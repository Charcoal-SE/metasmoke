class UsersController < ApplicationController
  before_action :authenticate_user!

  def username

  end

  def set_username
    current_user.username = params[:username]
    current_user.save!

    redirect_to dashboard_path
  end

  def apps
    @keys = ApiKey.find(current_user.api_tokens.pluck(:api_key_id))
  end

  def revoke_app
    @key = ApiKey.find params[:key_id]
    @tokens = ApiToken.where(:api_key => @key, :user => current_user)
    if @tokens.destroy_all
      flash[:success] = "Revoked access to your account from #{@key.app_name}."
    else
      flash[:danger] = "Could not revoke access - contact a metasmoke admin."
    end
    redirect_to url_for(:controller => :users, :action => :apps)
  end
end
