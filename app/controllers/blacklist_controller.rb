class BlacklistController < ApplicationController
  before_action :verify_code_admin, :except => [:index]

  def index
    @websites = BlacklistedWebsite.all
    respond_to do |format|
      format.html {
        @websites = @websites.paginate(:per_page => 100, :page => params[:page])
      }
      format.json {
        render :json => @websites
      }
    end
  end

  def add_website
    @website = BlacklistedWebsite.new
  end

  def create_website
    @website = BlacklistedWebsite.new(website_params)
    @website.save
    redirect_to url_for(:controller => :blacklist, :action => :index)
  end

  def deactivate_website
    @website = BlacklistedWebsite.find params[:id]
    @website.is_active = false
    @website.save
    redirect_to url_for(:controller => :blacklist, :action => :index)
  end

  private
    def website_params
      params.require(:blacklisted_website).permit(:host)
    end
end
