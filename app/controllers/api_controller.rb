# frozen_string_literal: true

class APIController < ApplicationController
  before_action :verify_key, except: %i[filter_generator api_docs filter_fields calculate_filter]
  before_action :verify_trusted_key, only: [:regex_search]
  before_action :set_pagesize, except: %i[filter_generator api_docs]
  before_action :verify_write_token, only: %i[create_feedback report_post spam_flag add_domain_tag]
  skip_before_action :verify_authenticity_token, only: %i[posts_by_url create_feedback report_post spam_flag post_deleted add_domain_tag
                                                          calculate_filter]

  # Public routes

  def api_docs
    redirect_to 'https://charcoal-se.org/ms/API-Documentation-(V2)'
  end

  # Routes for developer use

  def filter_generator; end

  # Read routes: Posts

  def posts
    filter = 'AAAAAAAAAAPHx4AAAAAAAUA='
    @posts = Post.where(id: params[:ids].split(';'))
                 .select(select_fields(filter))
                 .order(id: :desc)
                 .left_joins(:feedbacks)
                 .left_joins(:deletion_logs)
                 .includes(flag_logs: [:user])
    @results = @posts.paginate(page: params[:page], per_page: @pagesize)
    @more = has_more?(params[:page], @results.count)
    @results = @results.group(:id)
    render formats: :json
  end

  def posts_by_feedback
    filter = 'AAAAAAAAAAPHx4AAAAAAAUA='
    @posts = Post.all.joins(:feedbacks)
                 .where(feedbacks: { feedback_type: params[:type] })
                 .select(select_fields(filter))
                 .order(id: :desc)
                 .includes(:feedbacks)
                 .includes(flag_logs: [:user])
    results = @posts.paginate(page: params[:page], per_page: @pagesize)
    render json: { items: results, has_more: has_more?(params[:page], results.count) }
  end

  def posts_by_url
    filter = 'AAAAAAAAAAPHx4AAAAAAAUA='
    @posts = Post.where(link: params[:urls].split(';'))
                 .select(select_fields(filter))
                 .order(id: :desc)
                 .includes(feedbacks: [:user])
                 .includes(:deletion_logs)
                 .includes(flag_logs: [:user])
    @results = @posts.paginate(page: params[:page], per_page: @pagesize)
    @more = has_more?(params[:page], @results.count)
    @results = @results.group(:id)
    render 'posts.json.jbuilder'
  end

  def posts_by_site
    filter = 'AAAAAAAAAAPHx4AAAAAAAUA='
    @posts = Post.joins(:site)
                 .where(sites: { site_domain: params[:site] })
                 .select(select_fields(filter))
                 .order(id: :desc)
                 .includes(:feedbacks)
                 .includes(flag_logs: [:user])
    results = @posts.paginate(page: params[:page], per_page: @pagesize)
    render json: { items: results, has_more: has_more?(params[:page], results.count) }
  end

  def posts_by_daterange
    filter = 'AAAAAAAAAAPHx4AAAAAAAUA='
    @posts = Post.where(created_at: DateTime.strptime(params[:from_date], '%s')..DateTime.strptime(params[:to_date], '%s'))
                 .includes(:feedbacks)
                 .includes(flag_logs: [:user])
    results = @posts.select(select_fields(filter)).order(id: :desc).paginate(page: params[:page], per_page: @pagesize)
    render json: { items: results, has_more: has_more?(params[:page], results.count) }
  end

  def undeleted_posts
    filter = 'AAAAAAAAAAPHx4AAAAAAAUA='
    @posts = Post.where(deleted_at: nil).select(select_fields(filter)).includes(:feedbacks).includes(flag_logs: [:user])
    results = @posts.order(id: :desc).paginate(page: params[:page], per_page: @pagesize)
    render json: { items: results, has_more: has_more?(params[:page], results.count) }
  end

  def post_feedback
    filter = 'AAAAAI0JAAAAAAAAAAAAAAA='
    @feedbacks = Feedback.where(post_id: params[:id]).select(select_fields(filter)).order(id: :desc)
    results = @feedbacks.paginate(page: params[:page], per_page: @pagesize)
    render json: { items: results, has_more: has_more?(params[:page], results.count) }
  end

  def post_reasons
    filter = 'AAAAAAAAAAAAABgAAAAAAAA='
    @reasons = Reason.joins(:posts).where(posts_reasons: { post_id: params[:id] }).select(select_fields(filter)).order(id: :desc)
    results = @reasons.paginate(page: params[:page], per_page: @pagesize)
    render json: { items: results, has_more: has_more?(params[:page], results.count) }
  end

  def post_valid_feedback
    @post = Post.find params[:id]
    render formats: :json
  end

  def search_posts
    filter = 'AAAAAAAAAAPHx4AAAAAAAUA='
    @posts = Post.all
    if params[:feedback_type].present?
      @posts = @posts.includes(:feedbacks).where(feedbacks: { feedback_type: params[:feedback_type] })
    end
    if params[:site].present?
      @posts = @posts.joins(:site).where(sites: { site_domain: params[:site] })
    end
    if params[:from_date].present?
      @posts = @posts.where('`posts`.`created_at` > ?', DateTime.strptime(params[:from_date], '%s'))
    end
    if params[:to_date].present?
      @posts = @posts.where('`posts`.`created_at` < ?', DateTime.strptime(params[:to_date], '%s'))
    end
    if params[:autoflagged].present?
      @posts = @posts.where(autoflagged: params[:autoflagged])
    end
    results = @posts.select(select_fields(filter)).order(id: :desc).paginate(page: params[:page], per_page: @pagesize)
    render json: { items: results, has_more: has_more?(params[:page], results.count) }
  end

  # Read routes: Reasons

  def reasons
    filter = 'AAAAAAAAAAAAABgAAAAAAAA='
    @reasons = Reason.where(id: params[:ids].split(';')).select(select_fields(filter)).order(id: :desc)
    results = @reasons.paginate(page: params[:page], per_page: @pagesize)
    render json: { items: results, has_more: has_more?(params[:page], results.count) }
  end

  def all_reasons
    filter = 'AAAAAAAAAAAAABgAAAAAAAA='
    @reasons = Reason.all.select(select_fields(filter)).order(id: :desc)
    results = @reasons.paginate(page: params[:page], per_page: @pagesize)
    render json: { items: results, has_more: has_more?(params[:page], results.count) }
  end

  def reason_posts
    filter = 'AAAAAAAAAAPHx4AAAAAAAUA='
    @posts = Post.joins(:posts_reasons).where(posts_reasons: { reason_id: params[:id] }).select(select_fields(filter)).order(id: :desc)
    results = @posts.paginate(page: params[:page], per_page: @pagesize)
    render json: { items: results, has_more: has_more?(params[:page], results.count) }
  end

  # Read routes: BlacklistedWebsites

  def blacklisted_websites
    @websites = BlacklistedWebsite.active
    results = @websites.order(id: :desc).paginate(page: params[:page], per_page: @pagesize)
    render json: { items: results, has_more: has_more?(params[:page], results.count) }
  end

  # Read routes: Users

  def users_with_code_privs
    chat_ids = User.blacklist_managers.pluck(:stackexchange_chat_id, :stackoverflow_chat_id, :meta_stackexchange_chat_id)

    items = {}
    %w[stackexchange_chat_ids stackoverflow_chat_ids meta_stackexchange_chat_ids].each_with_index do |name, index|
      items[name] = chat_ids.map { |a| a[index] }.select(&:present?)
    end

    render json: { items: items }
  end

  def users
    filter = 'AAAAAAAAAAAAAAAAAAAB+AA='

    users = if params[:role]
              User.with_role(params[:role])
            else
              User.all
            end

    @users = users.select(select_fields(filter)).order(id: :asc).paginate(page: params[:page], per_page: @pagesize)
    @has_more = has_more?(params[:page], @users.count)
    render formats: [:json]
  end

  # Read routes Status

  def current_status
    render json: { last_ping: SmokeDetector.where.not(location: params[:except]).maximum(:last_ping) }
  end

  # Read routes: SmokeDetectors

  def smoke_detectors
    filter = 'AAAAAAAAAAAAAAAADQAAAAE='
    fields = select_fields(filter) - ['smoke_detectors.access_token']

    smokeys = SmokeDetector.all.select(fields).order(id: :asc)
    smokeys = smokeys.where(user_id: params[:owner]) if params[:owner].present?

    render json: { items: smokeys }
  end

  # Read routes: App stuff

  def filter_fields
    i = -1
    render json: AppConfig['api_field_mappings'].map { |f| [f, i += 1] }.to_h
  end

  def spam_last_week
    render json: Site.joins(:posts).where(posts: { is_tp: true, created_at: 1.week.ago.to_date..Date.today })
      .group(Arel.sql('sites.site_name')).count
  end

  def detailed_ttd
    no_flags = Post.group_by_hour_of_day('`posts`.`created_at`')
                   .select(Arel.sql('AVG(TIMESTAMPDIFF(SECOND, `posts`.`created_at`, `deletion_logs`.`created_at`)) as time_to_deletion'))
                   .joins(:deletion_logs)
                   .where(is_tp: true)
                   .where('`posts`.`created_at` < ?', Date.new(2017, 1, 1))
                   .where('TIMESTAMPDIFF(SECOND, `posts`.`created_at`, `deletion_logs`.`created_at`) <= 3600').relation.each_with_index
                   .map { |a, i| [i, a.time_to_deletion.round(0)] }
    one_flag = Post.group_by_hour_of_day('`posts`.`created_at`')
                   .select(Arel.sql('AVG(TIMESTAMPDIFF(SECOND, `posts`.`created_at`, `deletion_logs`.`created_at`)) as time_to_deletion'))
                   .joins(:deletion_logs)
                   .where(is_tp: true)
                   .where('`posts`.`created_at` >= ?', Date.new(2017, 1, 1))
                   .where('`posts`.`created_at` < ?', Date.new(2017, 2, 14))
                   .where('TIMESTAMPDIFF(SECOND, `posts`.`created_at`, `deletion_logs`.`created_at`) <= 3600').relation.each_with_index
                   .map { |a, i| [i, a.time_to_deletion.round(0)] }
    three_flags = Post.group_by_hour_of_day('`posts`.`created_at`')
                      .select(Arel.sql('AVG(TIMESTAMPDIFF(SECOND, `posts`.`created_at`, `deletion_logs`.`created_at`)) as time_to_deletion'))
                      .joins(:deletion_logs)
                      .where(is_tp: true)
                      .where('`posts`.`created_at` >= ?', Date.new(2017, 2, 14))
                      .where('TIMESTAMPDIFF(SECOND, `posts`.`created_at`, `deletion_logs`.`created_at`) <= 3600').relation.each_with_index
                      .map { |a, i| [i, a.time_to_deletion.round(0)] }
    render json: [
      { name: '0 flags', data: no_flags },
      { name: '1 flag', data: one_flag },
      { name: '3 flags', data: three_flags }
    ]
  end

  # Write routes

  def create_feedback
    @post = Post.find params[:id]
    @feedback = Feedback.new(user: @user, post: @post, api_key: @key)
    @feedback.feedback_type = params[:type]

    if @post.question? && @feedback.is_naa?
      render status: 500, json: { error_name: 'failed', error_code: 500, error_message: "NAA feedback isn't allowed on questions" }
      return
    end

    if @feedback.save
      if @feedback.is_naa?
        begin
          ActionCable.server.broadcast 'smokedetector_messages', naa: { post_link: @post.link }
        rescue # rubocop:disable Lint/HandleExceptions
        end
      elsif @feedback.is_negative?
        begin
          ActionCable.server.broadcast 'smokedetector_messages', fp: { post_link: @post.link }
        rescue # rubocop:disable Lint/HandleExceptions
        end
      end
      render json: @post.feedbacks, status: 201
    else
      render status: 500, json: { error_name: 'failed', error_code: 500, error_message: 'Feedback object failed to save.' }
    end
  end

  def report_post
    # We don't create any posts here, just send them on to Smokey to do all the processing
    ActionCable.server.broadcast 'smokedetector_messages', report: { user: @user.username, post_link: params[:post_link] }

    render plain: 'OK', status: 201
  end

  def spam_flag
    @post = Post.find params[:id]

    unless @user.write_authenticated && @user.flags_enabled
      render status: 409, json: {
        error_name: 'not_write_authenticated',
        error_code: 409,
        error_message: 'Current user is not write-authenticated.'
      }
      return
    end

    status, message = @user.spam_flag(@post, false)
    FlagLog.create(
      success: status,
      error_message: status.present? ? nil : message,
      is_dry_run: false,
      flag_condition: nil,
      user: @user,
      post: @post,
      backoff: status.present? ? message : 0,
      site_id: @post.site_id,
      is_auto: false,
      api_key: @key
    )
    if status
      render json: { status: 'success', backoff: message }
    else
      render status: 500, json: { status: 'failed', message: message }
    end
  end

  def post_deleted
    unless @key.is_trusted
      render(status: 403, json: { status: 'failed', message: 'The API key used to make the request is not trusted.' }) && return
    end

    post = Post.find params[:id]
    dl = post.deletion_logs.new(api_key_id: @key.id, is_deleted: true)

    if dl.save
      render json: { status: 'success' }
    else
      render status: 500, json: { status: 'failed', message: 'The deletion log failed to save.' }
    end
  end

  def post_domains
    post = Post.find params[:id]
    results = post.spam_domains
    render json: { items: results.paginate(page: params[:page], per_page: @pagesize), has_more: has_more?(params[:page], results.count) }
  end

  def domain_tags
    domain = SpamDomain.find params[:id]
    results = domain.domain_tags
    render json: { items: results.paginate(page: params[:page], per_page: @pagesize), has_more: has_more?(params[:page], results.count) }
  end

  def add_domain_tag
    domain = SpamDomain.find params[:id]
    tag = DomainTag.find_or_create_by name: params[:tag]
    domain.domain_tags << tag
    results = domain.domain_tags.limit(@pagesize)
    render json: { success: true, items: results, more_url: api_domain_tags_url(domain) }
  end

  def calculate_filter
    filter = Filterator::V2.filter_from_fields(params[:fields])
    render json: { filter: filter }
  end

  private

  def verify_key
    @key = APIKey.find_by(key: params[:key])
    return if params[:key].present? && @key.present?
    smokey = SmokeDetector.find_by(access_token: params[:key])
    return if smokey.present?
    render status: 403, json: {
      error_name: 'unauthenticated',
      error_code: 403,
      error_message: 'No key was passed or the passed key is invalid.'
    }
  end

  def set_pagesize
    @pagesize = [(params[:per_page] || 10).to_i, 100].min
  end

  def has_more?(page, result_count) # rubocop:disable Style/PredicateName
    (page || 1).to_i * @pagesize < result_count
  end

  def verify_write_token
    # This method deliberately doesn't check expiry: tokens are valid for authorization
    # forever, but can only be fetched using the code in the first 10 minutes.
    @token = APIToken.where(token: params[:token], api_key: @key)
    unless @token.any?
      render status: 401, json: {
        error_name: 'unauthorized',
        error_code: 401,
        error_message: 'The token provided does not supply authorization to perform this action.'
      }
      return
    end

    @token = @token.first
    @user = @token.user
  end

  def select_fields(default = '')
    Filterator::V1.fields_from_string(params[:filter] || default)
  end

  def verify_trusted_key
    return if @key.present? && @key.is_trusted
    render status: 403, json: {
      error_name: 'trusted_key_required',
      error_code: 403,
      error_message: 'The requested action requires the presented key to be trusted.'
    }
  end
end
