class UsersController < ApplicationController
  before_action :authenticate_user!

  def username
    
  end

  def set_username
    current_user.username = params[:username]
    current_user.save!

    redirect_to dashboard_path
  end
end
