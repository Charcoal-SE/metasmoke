class BlacklistController < ApplicationController
  before_action :verify_code_admin, :except => [:index]

  def index
    @websites = BlacklistedWebsite.all.paginate(:per_page => 100, :page => params[:page])
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
end
