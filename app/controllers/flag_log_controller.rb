class FlagLogController < ApplicationController
  def index
    @flag_logs = FlagLog.all.order('created_at DESC').includes(:post => [:feedbacks => [:user, :api_key]]).includes(:post => [:reasons]).includes(:user).paginate(:page => params[:page], :per_page => 100)
    @sites = Site.where(:id => @flag_logs.map(&:post).map(&:site_id)).to_a
  end

  def by_post
    @individual_post = Post.find(params[:id])
    @flag_logs = @individual_post.flag_logs.order('created_at DESC').includes(:post => [:feedbacks => [:user, :api_key]]).includes(:post => [:reasons]).includes(:user).paginate(:page => params[:page], :per_page => 100)
    @sites = Site.where(:id => @flag_logs.map(&:post).map(&:site_id)).to_a
    render :index
  end

  def not_flagged
    @posts = Post.left_joins(:flag_logs).where(:flag_logs => { :id => nil }).paginate(:page => params[:page], :per_page => 100)
  end
end
