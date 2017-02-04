class UserSiteSettingsController < ApplicationController
  before_action :authenticate_user!
  before_action :verify_admin, :only => [:for_user]
  before_action :set_preference, :only => [:edit, :update, :destroy]
  before_action :verify_authorized, :only => [:edit, :update, :destroy]

  def index
    @preferences = UserSiteSetting.where(:user => current_user)
  end

  def for_user
    @user = User.find params[:user]
    @preferences = UserSiteSetting.where(:user => @user)
  end

  def enable_flagging
    if (FlagSetting["registration_enabled"] == "0" || !current_user.has_role?(:flagger)) and not current_user.flags_enabled
      render :json => { :status => "nope" }, :status => 500
      return
    end

    if current_user.update(:flags_enabled => params[:enable])
      render :json => { :status => "ok" }
    else
      render :json => { :status => "nope" }, :status => 500
    end
  end

  def new
    @preference = UserSiteSetting.new
  end

  def create
    @preference = UserSiteSetting.new preference_params
    @preference.user = current_user
    @preference.site_ids = params[:user_site_setting][:sites]

    if @preference.save
      flash[:success] = "Saved your preferences."
      redirect_to url_for(:controller => :user_site_settings, :action => :index)
    else
      render :new, :status => 422
    end
  end

  def edit
  end

  def update
    @preference.sites = params[:user_site_setting][:sites].map{ |i| Site.find i.to_i if i.present? }.compact
    if @preference.update preference_params
      flash[:success] = "Saved your preferences."
      redirect_to url_for(:controller => :user_site_settings, :action => :index)
    else
      render :edit, :status => 422
    end
  end

  def destroy
    if @preference.destroy
      flash[:success] = "Removed your preferences."
    else
      flash[:danger] = "Failed to remove your preferences - contact a developer to find out why."
    end
    redirect_to url_for(:controller => :user_site_settings, :action => :index)
  end

  private
  def set_preference
    @preference = UserSiteSetting.find params[:id]
  end

  def preference_params
    params.require(:user_site_setting).permit(:max_flags)
  end

  def verify_authorized
    unless current_user.has_role?(:admin) || @preference.user == current_user
      raise ActionController::RoutingError.new('Not Found')
    end
  end
end
