class UserSiteSettingsController < ApplicationController
  before_action :authenticate_user!
  before_action :verify_admin, :only => [:for_user]

  def index
    @preferences = UserSiteSetting.where(:user => current_user)
  end

  def for_user
    @preferences = UserSiteSetting.where(:user_id => params[:user])
  end

  def new
    @preference = UserSiteSetting.new
  end

  def create
    @preference = UserSiteSetting.new preference_params
    @preference.sites = params[:user_site_setting][:sites].map{ |i| Site.find i.to_i if i.present? }.compact

    if @preference.save
      flash[:success] = "Saved your preferences."
      redirect_to url_for(:controller => :user_site_settings, :action => :index)
    else
      render :new, :status => 422
    end
  end
end
