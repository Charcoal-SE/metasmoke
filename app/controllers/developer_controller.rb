class DeveloperController < ApplicationController
  before_action :authenticate_user!
  before_action :verify_developer

  def update_sites
    SitesHelper.updateSites
    flash[:info] = "The sites cache is being updated. Completion estimated at ~30s."
    redirect_back(:fallback_location => url_for(:controller => :dashboard, :action => :index))
  end

  private
    def verify_developer
      unless current_user.has_role?(:developer)
        raise ActionController::RoutingError.new('Not Found') and return
      end
    end
end
