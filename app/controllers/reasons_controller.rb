class ReasonsController < ApplicationController
  def show
    @reason = Reason.find(params[:id])
    @posts = @reason.posts.includes(:reasons).includes(:feedbacks).last(10)
  end
end
