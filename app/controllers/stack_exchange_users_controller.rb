class StackExchangeUsersController < ApplicationController
  def index
    @users = StackExchangeUser.joins(:feedbacks).where("still_alive = true").where("stack_exchange_users.site_id = 1").where("feedbacks.feedback_type LIKE '%t%'").includes(:site).group(:user_id).last(100)
  end
end
