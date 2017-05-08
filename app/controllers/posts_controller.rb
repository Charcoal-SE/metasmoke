class PostsController < ApplicationController
  protect_from_forgery except: [:create]
  before_action :check_if_smokedetector, only: :create
  before_action :set_post, only: [:needs_admin, :feedbacksapi, :reindex_feedback, :cast_spam_flag, :delete_post]
  before_action :authenticate_user!, only: [:reindex_feedback, :cast_spam_flag]
  before_action :verify_developer, only: [:reindex_feedback, :delete_post]

  def show
    begin
      @post = Post.joins("LEFT JOIN `sites` ON `sites`.`id` = `posts`.`site_id`").joins(:reasons).select("posts.*, sites.site_logo, SUM(reasons.weight) AS reason_weight").find(params[:id])
    rescue
      @post = Post.find params[:id]
    end
  end

  # Render bodies on-demand for fancy expanding rows
  def body
    @post = Post.where(id: params[:id]).select(:body, :id).includes(:reasons).first
    render layout: false
  end

  def latest
    redirect_to url_for(controller: :posts, action: :show, id: Post.select("id").last.id.to_s)
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

  def recentpostsapi
    posts = Rails.cache.fetch("last-posts", expires_in: 30.seconds) do
      Post.joins(:site).select("posts.id, posts.title, posts.link, posts.created_at, sites.site_logo").order(:created_at).last(100)
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
      render json: { error: "You must be signed in to use the feedbacks API." }
    end
  end

  # GET /posts
  # GET /posts.json
  def index
    @posts = Post.all.includes_for_post_row.paginate(page: params[:page], per_page: 100).order('created_at DESC')

    if params[:filter] == "undeleted"
      @posts = @posts.where(deleted_at: nil)
    end

    @sites = Site.where(id: @posts.map(&:site_id)).to_a
  end

  # POST /posts
  # POST /posts.json
  def create
    @post = Post.new(post_params)

    @post.smoke_detector = @smoke_detector
    @post.site = Site.find_by_site_domain(URI.parse(@post.link).host)

    params["post"]["reasons"].each do |r|
      reason = Reason.find_or_create_by(reason_name: r.split("(").first.strip.humanize)

      reason.last_post_title = @post.title
      reason.inactive = false
      reason.save!

      @post.reasons << reason
    end


    begin
      user_id = @post.user_link.scan(/\/u(sers)?\/(\d*)/).first.second

      hash = {site_id: @post.site_id, user_id: user_id}
      se_user = StackExchangeUser.find_or_create_by(hash)
      se_user.reputation = @post.user_reputation
      se_user.username = @post.username

      se_user.save!

      @post.stack_exchange_user = se_user
    rescue
    end

    respond_to do |format|
      if @post.save
        format.json { render status: :created, plain: "OK" }
      else
        format.json { render json: @post.errors, status: :unprocessable_entity }
      end
    end
  end

  def needs_admin
    flag = Flag.new
    flag.reason = params[:reason]
    unless current_user.nil?
      flag.user_id = current_user.id
    end
    flag.post = @post
    flag.is_completed = false

    if flag.save
      render plain: "OK"
    else
      render plain: "Save failed.", status: :internal_server_error
    end
  end

  def reindex_feedback
    if @post.update_feedback_cache
      flash[:success] = "Feedback reindexed and corrected."
    else
      flash[:info] = "Feedback reindexed; no change."
    end
    redirect_to url_for(controller: :posts, action: :show, id: @post.id)
  end

  def delete_post
    if @post.destroy
      flash[:success] = "Post destroyed successfully"
    else
      flash[:warning] = "Something went wrong when destroying post."
    end

    SmokeDetector.send_message_to_charcoal "Metasmoke post #{@post.id} (#{@post.title}) destroyed by #{@current_user.username}"

    redirect_to posts_path
  end

  def cast_spam_flag
    unless current_user.api_token.present?
      flash[:warning] = "You must be write-authenticated to cast a spam flag."
      redirect_to authentication_status_path and return
    end

    result, message = current_user.spam_flag(@post, false)

    flag_log = FlagLog.create(success: result, error_message: result.present? ? nil : message,
                              is_dry_run: false, flag_condition: nil,
                              user: current_user, post: @post, backoff: result.present? ? message : 0,
                              site_id: @post.site_id, is_auto: false)

    if result
      flash[:success] = "Spam flag cast successfully."

      feedback = Feedback.new(feedback_type: "tpu-",
                              user_id: current_user.id,
                              post_id: @post.id)

      unless feedback.save
        flash[:danger] = "Unable to save feedback. Ping Undo."
      end
    else
      flash[:danger] = "Spam flag not cast: #{message}"
    end
    redirect_to url_for(controller: :posts, action: :show, id: params[:id])
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_post
      @post = Post.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def post_params
      params.require(:post).permit(:title, :body, :link, :post_creation_date, :reasons, :username, :user_link, :why, :user_reputation, :score, :upvote_count, :downvote_count)
    end
end
