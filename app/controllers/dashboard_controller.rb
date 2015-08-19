class DashboardController < ApplicationController
  before_filter :authenticate_user!

  def index
    @reasons = Reason.all
    @posts = Post.all
  end
end
