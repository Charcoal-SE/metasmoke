class StackExchangeUsersController < ApplicationController
  before_action :set_stack_exchange_user, :only => [:show]

  def index
    @users = StackExchangeUser.joins(:feedbacks).where("still_alive = true").where("stack_exchange_users.site_id = 1").where("feedbacks.feedback_type LIKE '%t%'").includes(:site).group(:user_id).order("created_at DESC").first(100)
  end

  def show
    @posts = @user.posts
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_stack_exchange_user
      begin
        @user = StackExchangeUser.joins(:site).select("stack_exchange_users.*, sites.site_logo").find(params[:id])
      rescue
        @user = StackExchangeUser.find(params[:id])
      end
    end
end
