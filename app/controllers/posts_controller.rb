# frozen_string_literal: true

class PostsController < ApplicationController
  protect_from_forgery except: [:create]
  before_action :check_if_smokedetector, only: :create
  before_action :set_post, only: %i[remove_domain add_domain needs_admin feedbacksapi reindex_feedback cast_spam_flag delete_post]
  before_action :authenticate_user!, only: %i[reindex_feedback cast_spam_flag]
  before_action :verify_developer, only: %i[reindex_feedback delete_post]
  before_action :verify_reviewer, only: %i[feedback cast_spam_flag]
  before_action :verify_core, only: %i[remove_domain add_domain]

  def show
    begin
      @post = Post.joins('LEFT JOIN `sites` ON `sites`.`id` = `posts`.`site_id`')
                  .joins(:reasons)
                  .includes(:feedbacks)
                  .select(Arel.sql('posts.*, sites.site_logo, SUM(reasons.weight) AS reason_weight'))
                  .find(params[:id])
    rescue # rubocop:disable Lint/HandleExceptions
    end
    @post = Post.find params[:id] if @post&.id.nil?

    @is_review_item = false

    not_found if @post&.id.nil?
  end

  def add_domain
    domain = SpamDomain.find_by(domain: params[:domain_name])
    if !domain.present?
      flash[:warning] = "Domain #{params[:domain_name]} not found"
    else
      PostSpamDomain.create(post: @post, spam_domain: domain, added_by: current_user)
    end
    redirect_back(fallback_location: post_path(@post))
  end

  def remove_domain
    domain = PostSpamDomain.find_by(post: @post, spam_domain: params[:domain_id])
    if domain.nil? || domain.added_by.nil?
      flash[:warning] = 'You can only delete user added spam domains'
    else
      domain.custom_delete
    end
    redirect_back(fallback_location: post_path(@post))
  end

  # Render bodies on-demand for fancy expanding rows
  def body
    @post = Post.where(id: params[:id]).select(:body, :id).includes(:reasons).first
    render layout: false
  end

  def latest
    redirect_to url_for(controller: :posts, action: :show, id: Post.select(Arel.sql('id')).last.id.to_s)
  end

  def by_url
    @posts = Post.where(link: params[:url])
    count = @posts.count

    if count < 1
      flash[:danger] = "Post not found for #{params[:url]}. It may have been reported during a period of metasmoke downtime."
      redirect_to posts_path
    elsif count == 1
      redirect_to url_for(controller: :posts, action: :show, id: @posts.first.id)
    else
      flash.now[:info] = 'Multiple records were found for this URL; pick the one you meant from this list.'
    end
  end

  def by_uid
    @posts = Post.joins(:site).where(sites: { api_parameter: params[:api_param] }, posts: { native_id: params[:native_id] })
    count = @posts.count

    if count < 1
      flash[:danger] = "Post not found for #{params[:api_param]}/#{params[:native_id]}. "\
                       'It may have been reported during a period of metasmoke downtime.'
      redirect_to posts_path
    elsif count == 1
      redirect_to url_for(controller: :posts, action: :show, id: @posts.first.id)
    else
      flash.now[:info] = 'Multiple records were found for this URL; pick the one you meant from this list.'
      render action: :by_url
    end
  end

  def recentpostsapi
    posts = Rails.cache.fetch('last-posts', expires_in: 30.seconds) do
      Post.joins(:site).select(Arel.sql('posts.id, posts.title, posts.link, posts.created_at, sites.site_logo')).order(:created_at).last(100)
    end

    posts.each do |p|
      p.title.gsub! '<', '&lt;'
      p.title.gsub! '>', '&gt;'
    end

    posts = posts.last([params[:size].to_i, 100].min).reverse

    render json: posts, status: 200
  end

  def feedbacksapi
    if user_signed_in?
      render json: @post.feedbacks.select(:id, :chat_user_id, :user_id, feedback_type)
    else
      render json: { error: 'You must be signed in to use the feedbacks API.' }
    end
  end

  # GET /posts
  # GET /posts.json
  def index
    page_num = [params[:page].to_i - 1, 0].max
    per_page = 100
    page = [page_num * per_page, (page_num + 1) * per_page - 1]
    k = 'posts'
    if params[:filter] == 'undeleted'
      k = 'undeleted_posts'
      # Move this code into Redis::Post#update_undeleted_cache
      Redis::Post.all(type: :set).difference('deleted').store('undeleted_posts/pre')
      Redis::Post.all(type: :zset).intersect('undeleted_posts/pre').store('undeleted_posts')
    end
    start = Time.now
    # Use paginate
    @posts = redis.zrevrange(k, *page).map do |id|
      Redis::Post.new(id)
    end
    endt = Time.now
    Rails.logger.info "Took #{endt - start} to build posts"
    @posts.define_singleton_method(:total_pages) { redis.zcard('posts') / 100 }
    @posts.define_singleton_method(:current_page) { page_num + 1 }
    @sites = Site.where(id: @posts.map(&:site_id)).to_a
  end

  # POST /posts
  # POST /posts.json
  def create
    @post = Post.new(post_params)

    @post.smoke_detector = @smoke_detector
    @post.site = Site.find_by(site_domain: URI.parse(@post.link).host)

    params['post']['reasons'].each do |r|
      reason = Reason.find_or_create_by(reason_name: r.split('(').first.strip.humanize)

      reason.last_post_title = @post.title
      reason.inactive = false
      reason.save!

      @post.reasons << reason
    end

    begin
      user_id = @post.user_link.scan(%r{/u(sers)?/(\d*)}).first.second

      hash = { site_id: @post.site_id, user_id: user_id }
      se_user = StackExchangeUser.find_or_create_by(hash)
      se_user.reputation = @post.user_reputation
      se_user.username = @post.username

      se_user.save!

      @post.stack_exchange_user = se_user
    rescue # rubocop:disable Lint/HandleExceptions
    end

    less_important_things(@post)

    respond_to do |format|
      if @post.save
        # Start autoflagging
        Rails.logger.warn "[autoflagging] #{@post.id}: post.save succeeded"

        AutoflagJob.perform_later @post.id

        format.json { render status: :created, plain: 'OK' }
      else
        format.json { render json: @post.errors, status: :unprocessable_entity }
      end
    end
  end

  def needs_admin
    flag = Flag.new
    flag.reason = params[:flag][:reason]
    flag.user_id = current_user.id unless current_user.nil?
    flag.post = @post
    flag.is_completed = false

    if flag.save
      render plain: 'OK'
    else
      render plain: 'Save failed.', status: :internal_server_error
    end
  end

  def reindex_feedback
    if @post.update_feedback_cache
      flash[:success] = 'Feedback reindexed and corrected.'
    else
      flash[:info] = 'Feedback reindexed; no change.'
    end
    redirect_to url_for(controller: :posts, action: :show, id: @post.id)
  end

  def delete_post
    if @post.destroy
      flash[:success] = 'Post destroyed successfully'
    else
      flash[:warning] = 'Something went wrong when destroying post.'
    end

    SmokeDetector.send_message_to_charcoal "Metasmoke post #{@post.id} (#{@post.title}) destroyed by #{@current_user.username}"

    redirect_to posts_path
  end

  def cast_spam_flag
    feedback = Feedback.new(feedback_type: 'tpu-',
                            user_id: current_user.id,
                            post_id: @post.id)

    flash[:danger] = 'Unable to save feedback. Ping Undo.' unless feedback.save

    unless current_user.write_authenticated && current_user.flags_enabled
      flash[:warning] = 'You must be write-authenticated to cast a spam flag.'
      redirect_to(authentication_status_path) && return
    end

    result, message = current_user.spam_flag(@post, false)

    FlagLog.create(success: result, error_message: result.present? ? nil : message,
                   is_dry_run: false, flag_condition: nil,
                   user: current_user, post: @post, backoff: result.present? ? message : 0,
                   site_id: @post.site_id, is_auto: false)

    if result
      flash[:success] = 'Spam flag cast successfully.'

    else
      flash[:danger] = "Spam flag not cast: #{message}"
    end
    redirect_to url_for(controller: :posts, action: :show, id: params[:id])
  end

  def feedback
    not_found unless %w[tp fp naa].include? params[:feedback_type]
    @post = Post.find params[:post_id]
    @post.feedbacks.create user: current_user, feedback_type: params[:feedback_type]
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_post
    @post = Post.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def post_params
    permitted = %w[title body markdown link post_creation_date reasons username user_link why user_reputation score upvote_count downvote_count]
    params.require(:post).permit(permitted)
  end

  def less_important_things(post)
    ri = ReviewItem.new(reviewable: post, queue: ReviewQueue['posts'], completed: false)
    ri_success = ri.save
    return if ri_success
    Rails.logger.warn "[post-create] review item create failed: #{ri.errors.full_messages.join(', ')}"
  end
end
