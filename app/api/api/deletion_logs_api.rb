# frozen_string_literal: true

module API
  class DeletionLogsAPI < API::Base
    get '/' do
      std_result DeletionLog.all.order(id: :desc), filter: FILTERS[:deletions]
    end

    get '/post/:id' do
      std_result DeletionLog.where(post_id: params[:id]).order(id: :desc), filter: FILTERS[:deletions]
    end
  end
end
