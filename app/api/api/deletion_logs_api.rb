module API
  class DeletionLogsAPI < API::Base
    prefix :deletion_logs

    get '/' do
      std_result DeletionLog.all.order(id: :desc), filter: 'OFNLKGOKFHJIKOJNIJOOHNILNKMLGIKGLN'
    end

    get '/post/:id' do
      std_result DeletionLog.where(post_id: params[:id]).order(id: :desc), filter: 'OFNLKGOKFHJIKOJNIJOOHNILNKMLGIKGLN'
    end
  end
end