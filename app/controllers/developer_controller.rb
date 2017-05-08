class DeveloperController < ApplicationController
  before_action :authenticate_user!, except: [:blank_page]
  before_action :verify_developer, except: [:blank_page]

  def update_sites
    SitesHelper.updateSites
    flash[:info] = "Site cache updated, refer to MiniProfiler for execution details."
    redirect_back(fallback_location: url_for(controller: :dashboard, action: :index))
  end

  def production_log
    @log = `tail -n 1000 log/production.log`
    @log.gsub!(/\e\[([;\d]+)?m/, '')
    @log.gsub!(/\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/, '')
    @log.gsub!(/\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}\b/i, '')
  end

  def blank_page
    render layout: false
  end

  def websocket_test
    @channels = ["api_feedback", "api_flag_logs", "api_deletion_logs", "flag_logs", "github_new_commit", "posts_realtime", "smokedetector_messages"]
  end

  def send_websocket_test
    ActionCable.server.broadcast params[:channel], JSON.parse(params[:content])
    flash[:info] = "Queued for broadcast."
    redirect_to url_for(controller: :developer, action: :websocket_test)
  end

  private
    def verify_developer
      unless current_user.has_role?(:developer)
        raise ActionController::RoutingError.new('Not Found') and return
      end
    end
end
