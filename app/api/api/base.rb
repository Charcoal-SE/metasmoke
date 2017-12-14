# frozen_string_literal: true

module API
  class Base < Grape::API
    format :json

    helpers do
      def current_user
        @current_user ||= @token.user
      end

      def authenticate_app!
        @key = APIKey.find_by key: params[:key]
        error!({ name: 'missing_key', detail: 'No key was provided or the provided key is invalid.' }, 403) unless @key.present?
      end

      def authenticate_user!
        @token = @key.api_tokens.find_by token: params[:token]
        error!({ name: 'missing_token', detail: 'No token was provided or the provided token is invalid.' }, 401) unless @token.present?
      end

      def fields(default)
        @fields ||= Filterator::V2.fields_from_filter(params[:filter] || default)
      end

      def role(*names)
        return if current_user.has_any_role?(*names)
        error!({ name: 'unauthorized', detail: 'The authenticated user does not have the required permissions for this action.' }, 403)
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
        { items: paginated(col.select(fields(opts[:filter]))), has_more: more?(col, **opts) }
      end

      def single_result(item, **_opts)
        { items: [item], has_more: false }
      end
    end

    before do
      authenticate_app!
    end

    mount API::DebugAPI => 'v2.0/debug'
    mount API::AnnouncementsAPI => 'v2.0/announcements'
    mount API::AppsAPI => 'v2.0/apps'
    mount API::CommitStatusesAPI => 'v2.0/commits'
    mount API::DeletionLogsAPI => 'v2.0/deletions'
    mount API::DomainTagsAPI => 'v2.0/tags'
    mount API::FeedbacksAPI => 'v2.0/feedbacks'
    mount API::PostsAPI => 'v2.0/posts'
    mount API::ReasonsAPI => 'v2.0/reasons'
  end
end
