# frozen_string_literal: true

module API
  class Base < Grape::API
    def self.filter(fields)
      Filterator::V2.filter_from_fields(fields)
    end

    FILTERS = {
      announcements: filter(Announcement.fields(:id, :text, :expiry)),
      apps: filter(APIKey.fields(:id, :app_name, :user_id, :github_link)),
      commits: filter(CommitStatus.fields(:id, :commit_sha, :status)),
      deletions: filter(DeletionLog.fields(:id, :post_id, :is_deleted)),
      tags: filter(DomainTag.fields(:id, :name, :description)),
      feedbacks: filter(Feedback.fields(:id, :feedback_type, :post_id, :user_id)),
      posts: filter(Post.fields(:id, :title, :link, :site_id, :user_link, :username, :user_reputation)),
      reasons: filter(Reason.fields(:id, :reason_name, :weight)),
      smokeys: filter(SmokeDetector.fields(:id, :last_ping, :location, :user_id)),
      domains: filter(SpamDomain.fields(:id, :domain, :whois)),
      users: filter(User.fields(:id, :username)),
      mods: filter(ModeratorSite.fields(:id, :user_id, :site_id)),
      sites: filter(Site.fields(:id, :site_name, :site_url)),
      comments: filter(PostComment.fields(:id, :user_id, :text))
    }.freeze

    format :json

    helpers do
      def current_user
        @current_user ||= @token.user
      end

      def authenticate_app!
        @key = APIKey.find_by(key: params[:key])
        if @key.nil? && SmokeDetector.find_by(access_token: params[:key])
          @key = APIKey.first
        end
        error!({ name: 'missing_key', detail: 'No key was provided or the provided key is invalid.' }, 403) if @key.blank?
      end

      def authenticate_user!
        @token = @key.api_tokens.find_by token: params[:token]
        error!({ name: 'missing_token', detail: 'No token was provided or the provided token is invalid.' }, 401) if @token.blank?
      end

      def authenticate_smokey!
        return if SmokeDetector.find_by(access_token: params[:key]).present?
        error!({ name: 'insufficient_authorization', detail: 'The requested action requires a higher level of authorization than '\
                 'the key provides.' }, 401)
      end

      def fields(default)
        @fields ||= Filterator::V2.fields_from_filter(params[:filter] || default)
      end

      def role(*names)
        return if current_user.has_any_role?(*names)
        error!({ name: 'unauthorized', detail: 'The authenticated user does not have the required permissions for this action.' }, 403)
      end

      def trusted_key
        return if @key.is_trusted
        error!({ name: 'untrusted_key', detail: 'The presented key is not trusted.' }, 403)
      end

      def per_page
        [(params[:per_page] || 10).to_i, 100].min
      end

      def more?(col, **opts)
        ctr = if opts[:countable].nil? || opts[:countable] == true
                col.count
              else
                col.to_a.size
              end
        ctr > per_page * (params[:page]&.to_i || 1)
      end

      def paginated(col)
        col.paginate(page: params[:page], per_page: per_page)
      end

      def std_result(col, **opts)
        items = if !opts[:countable].nil? && !opts[:countable]
                  col
                else
                  paginated(col.select(fields(opts[:filter])))
                end
        more = if !opts[:countable].nil? && !opts[:countable]
                 opts[:more]
               else
                 more?(col, **opts)
               end
        { items: items, has_more: more }
      end

      def single_result(item, **_opts)
        { items: [item], has_more: false }
      end

      def render(template_name, **locals)
        file = Rails.root.join 'app/views', template_name
        template = File.read file
        ERB.new(template).result(OpenStruct.new(locals).instance_eval { binding })
      end
    end

    before do
      key = APIKey.find_by(key: params[:key])
      smokey_token = key.nil? ? SmokeDetector.find_by(access_token: params[:key]) : nil
      request_time ||= Time.now.to_f
      uuid = request.env['action_dispatch.request_id']
      redis_log_key = "request/#{request_time}/#{uuid}"
      request.set_header 'redis_logs.log_key', redis_log_key
      request.set_header 'redis_logs.timestamp', request_time
      request.set_header 'redis_logs.request_id', uuid
      redis.zadd 'requests', request_time, uuid
      { request_headers: headers.except('Cookie'), params: params.except(:key) }.each do |k, v|
        next if v.empty?
        redis.multi do
          redis.mapped_hmset "#{redis_log_key}/#{k}", v
          redis.expire "#{redis_log_key}/#{k}", REDIS_LOG_EXPIRATION
        end
      end
      redis.mapped_hmset redis_log_key, status: 'INC',
                                        path: request.path,
                                        api_key_id: key&.id,
                                        smoke_detector_id: smokey_token&.id,
                                        sha: CurrentCommit
      redis.expire redis_log_key, REDIS_LOG_EXPIRATION
      RedisLogJob.perform_later(uuid, request_time)
      authenticate_app!
    end

    content_type :atom, 'application/atom+xml'
    content_type :rss, 'application/rss+xml'

    mount API::DebugAPI => 'v2.0/debug'
    mount API::AnnouncementsAPI => 'v2.0/announcements'
    mount API::AppsAPI => 'v2.0/apps'
    mount API::CommitStatusesAPI => 'v2.0/commits'
    mount API::DeletionLogsAPI => 'v2.0/deletions'
    mount API::DomainTagsAPI => 'v2.0/tags'
    mount API::FeedbacksAPI => 'v2.0/feedbacks'
    mount API::PostsAPI => 'v2.0/posts'
    mount API::ReasonsAPI => 'v2.0/reasons'
    mount API::SmokeDetectorsAPI => 'v2.0/smokeys'
    mount API::SpamDomainsAPI => 'v2.0/domains'
    mount API::UsersAPI => 'v2.0/users'
    mount API::ModeratorSitesAPI => 'v2.0/mods'
    mount API::SitesAPI => 'v2.0/sites'
    mount API::CommentsAPI => 'v2.0/comments'
  end
end
