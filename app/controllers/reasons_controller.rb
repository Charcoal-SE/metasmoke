class ReasonsController < ApplicationController
  def show
    @reason = Reason.find(params[:id])
    @posts = @reason.posts.includes(:reasons).includes(:feedbacks).paginate(:page => params[:page], :per_page => 100).order('created_at DESC')
    @sites = Site.where(:id => @posts.map(&:site_id))
  end
end
