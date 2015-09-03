class ReasonsController < ApplicationController
  def show
    @reason = Reason.find(params[:id])
    @posts = @reason.posts.includes(:reasons).includes(:feedbacks).paginate(:page => params[:page], :per_page => 10).order('created_at DESC')
  end
end
