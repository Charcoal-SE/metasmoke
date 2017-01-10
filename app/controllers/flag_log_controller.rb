class FlagLogController < ApplicationController
  def index
    @flag_logs = FlagLog.all.order('created_at DESC').includes(:post => [:feedbacks => [:user, :api_key]]).includes(:post => [:reasons]).includes(:user).paginate(:page => params[:page], :per_page => 100)
  end

  def by_post
    @individual_post = Post.find(params[:id])
    @flag_logs = @individual_post.flag_logs.order('created_at DESC').includes(:post => [:feedbacks => [:user, :api_key]]).includes(:post => [:reasons]).includes(:user).paginate(:page => params[:page], :per_page => 100)
    render :index
  end

  def not_flagged
    @posts = Post.left_joins(:flag_logs).where(:flag_logs => { :id => nil }).order(:created_at => :desc).paginate(:page => params[:page], :per_page => 100)
  end
end
