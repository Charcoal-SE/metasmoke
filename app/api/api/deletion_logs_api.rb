# frozen_string_literal: true

module API
  class DeletionLogsAPI < API::Base
    get '/' do
      std_result DeletionLog.all.order(id: :desc), filter: FILTERS[:deletions]
    end

    get '/post/:id' do
      std_result DeletionLog.where(post_id: params[:id]).order(id: :desc), filter: FILTERS[:deletions]
    end

    before do
      authenticate_user!
      trusted_key
    end

    params do
      requires :key, type: String
      requires :is_deleted, type: Boolean
      optional :uncertainty, type: Integer
      optional :timestamp, type: DateTime
    end

    post '/post/:id' do
      create_opts = { is_deleted: params[:is_deleted], post_id: params[:id], api_key: @key }
      create_opts[:uncertainty] = params[:uncertainty] if params[:uncertainty].present?
      create_opts[:created_at] = params[:timestamp] if params[:timestamp].present?
      log = DeletionLog.create(**create_opts)
      single_result log
    end
  end
end
