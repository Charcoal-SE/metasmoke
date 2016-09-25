class ReasonsController < ApplicationController
  def show
    @reason = Reason.find(params[:id])
    @posts = @reason.posts.select(:id, :title, :site_id).includes(:reasons, :feedbacks).includes(:feedbacks => [:user, :api_key]).paginate(:page => params[:page], :per_page => 100).order('created_at DESC')
    @sites = Site.where(:id => @posts.map(&:site_id)).to_a
  end
end
