class SiteSettingsController < ApplicationController
  before_action :verify_admin
  skip_before_action :verify_authenticity_token, only: [:update]

  def index
    @settings = SiteSetting.all.paginate(page: params[:page], per_page: 20)
  end

  def update
    SiteSetting[params[:name]] = params[:value]
    render json: { success: true }, status: 202
  end

  def destroy
    SiteSetting.find(params[:id]).destroy
    flash[:success] = 'Removed setting.'
    redirect_to site_settings_path
  end
end
