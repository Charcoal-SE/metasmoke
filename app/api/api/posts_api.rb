# frozen_string_literal: true

module API
  class PostsAPI < API::Base
    get '/' do
      std_result Post.all.order(id: :desc), filter: FILTERS[:posts]
    end

    params do
      requires :key, type: String
      optional :site, type: String
    end
    get 'search.atom' do
      @posts = Post.all

      if params[:site].present?
        @posts = @posts.joins(:site).where(sites: { site_domain: params[:site] })
      end

      @posts = @posts.order(id: :desc)
      @posts = paginated(@posts)

      # noinspection RubyArgCount
      content_type 'application/atom+xml'
      render 'api/posts_atom.xml.erb', posts: @posts
    end

    params do
      requires :key, type: String
      optional :site, type: String
    end
    get 'search.rss' do
      @posts = Post.all

      if params[:site].present?
        @posts = @posts.joins(:site).where(sites: { site_domain: params[:site] })
      end

      @posts = @posts.order(id: :desc)
      @posts = paginated(@posts)

      # noinspection RubyArgCount
      content_type 'application/rss+xml'
      render 'api/posts_rss.xml.erb', posts: @posts
    end

    params do
      requires :key, type: String
      requires :from, type: DateTime
      requires :to, type: DateTime
    end
    get 'between' do
      std_result Post.where('created_at > ?', params[:from]).where('created_at < ?', params[:to]).order(id: :desc),
                 filter: FILTERS[:posts]
    end

    params do
      requires :key, type: String
      requires :site, type: String
    end
    get 'site' do
      std_result Post.joins(:site).where(sites: { site_domain: params[:site] }).order(id: :desc), filter: FILTERS[:posts]
    end

    params do
      requires :key, type: String
      requires :urls, type: String
    end
    get 'urls' do
      std_result Post.where(link: params[:urls].split(',')).order(id: :desc), filter: FILTERS[:posts]
    end

    params do
      requires :key, type: String
      requires :type, type: String
    end
    get 'feedback' do
      std_result Post.joins(:feedbacks).where(feedbacks: { feedback_type: params[:type] }).order(id: :desc),
                 filter: FILTERS[:posts]
    end

    get 'undeleted' do
      std_result Post.where(deleted_at: nil).order(id: :desc), filter: FILTERS[:posts]
    end

    get 'uid/:api_param/:native_id' do
      std_result Post.joins(:site).where(sites: { api_parameter: params[:api_param] }, posts: { native_id: params[:native_id] }),
                 filter: FILTERS[:posts]
    end

    get ':ids' do
      std_result Post.where(id: params[:ids].split(',')).order(id: :desc), filter: FILTERS[:posts]
    end

    get ':id/reasons' do
      std_result Post.find(params[:id]).reasons.order(id: :desc), filter: FILTERS[:reasons]
    end

    get ':id/domains' do
      std_result Post.find(params[:id]).spam_domains.order(id: :desc), filter: FILTERS[:domains]
    end

    get ':id/flags' do
      post = Post.find params[:id]
      flag_data = {
        id: post.id,
        autoflagged: {
          flagged: post.flag_logs.auto.successful.any?,
          users: post.flag_logs.auto.successful.includes(:user).map do |u|
            user = u.user
            { id: user&.id, username: user&.username, stackexchange_chat_id: user&.stackexchange_chat_id,
              stackoverflow_chat_id: user&.stackoverflow_chat_id, meta_chat_id: user&.meta_stackexchange_chat_id }
          end
        },
        manual_flags: {
          users: post.flag_logs.manual.successful.includes(:user).map do |u|
            user = u.user
            { id: user&.id, username: user&.username, stackexchange_chat_id: user&.stackexchange_chat_id,
              stackoverflow_chat_id: user&.stackoverflow_chat_id, meta_chat_id: user&.meta_stackexchange_chat_id }
          end
        }
      }
      single_result flag_data
    end

    before do
      authenticate_user!
      role :reviewer
    end

    params do
      requires :key, type: String
      requires :token, type: String
      requires :url, type: String
    end
    post 'report' do
      ActionCable.server.broadcast 'smokedetector_messages', report: { user: current_user.username, post_link: params[:url] }
      status 202
      { status: 'Accepted' }
    end

    params do
      requires :key, type: String
      requires :token, type: String
    end
    post ':id/flag' do
      post = Post.find params[:id]

      unless current_user.write_authenticated && current_user.flags_enabled
        error!({
                 error_name: 'not_write_authenticated',
                 error_code: 409,
                 error_message: 'Current user is not write-authenticated.'
               }, 409)
      end

      flag_type = params[:flag_type].present? ? params[:flag_type] : :spam
      status, message = current_user.flag(flag_type, post, false)
      FlagLog.create(
        success: status,
        error_message: status.present? ? nil : message,
        is_dry_run: false,
        flag_condition: nil,
        user: current_user,
        post: post,
        backoff: status.present? ? message : 0,
        site_id: post.site_id,
        is_auto: false,
        api_key: @key,
        flag_type: flag_type.to_s
      )
      if status
        { status: 'success', backoff: message }
      else
        status 500
        { status: 'failed', message: message }
      end
    end
  end
end
