class DeveloperController < ApplicationController
  before_action :authenticate_user!, :except => [:blank_page]
  before_action :verify_developer, :except => [:blank_page]

  def update_sites
    SitesHelper.updateSites
    flash[:info] = "Site cache updated, refer to MiniProfiler for execution details."
    redirect_back(:fallback_location => url_for(:controller => :dashboard, :action => :index))
  end

  def production_log
    @log = `tail -n 1000 log/production.log`
    @log.gsub!(/\e\[([;\d]+)?m/, '')
    @log.gsub!(/\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/, '')
    @log.gsub!(/\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}\b/i, '')
  end

  def blank_page
    render :layout => false
  end

  private
    def verify_developer
      unless current_user.has_role?(:developer)
        raise ActionController::RoutingError.new('Not Found') and return
      end
    end
end
