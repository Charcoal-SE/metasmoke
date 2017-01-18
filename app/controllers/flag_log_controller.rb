class FlagLogController < ApplicationController
  def index
    @individual_user = User.find(params[:user_id]) if params[:user_id].present?

    if @individual_user
      @applicable_flag_logs = @individual_user.flag_logs
    else
      @applicable_flag_logs = FlagLog.all
    end

    @flag_logs = @applicable_flag_logs.order('created_at DESC').includes(:post => [:feedbacks => [:user, :api_key]]).includes(:post => [:reasons]).includes(:user).paginate(:page => params[:page], :per_page => 100)
    @sites = Site.where(:id => @flag_logs.map(&:post).map(&:site_id)).to_a
  end

  def by_post
    @individual_post = Post.find(params[:id])
    @flag_logs = @individual_post.flag_logs.order('created_at DESC').includes(:post => [:feedbacks => [:user, :api_key]]).includes(:post => [:reasons]).includes(:user).paginate(:page => params[:page], :per_page => 100)
    @sites = Site.where(:id => @flag_logs.map(&:post).map(&:site_id)).to_a
    render :index
  end

  def not_flagged
    @posts = Post.left_joins(:flag_logs).where(:flag_logs => { :id => nil }).order(:created_at => :desc).paginate(:page => params[:page], :per_page => 100)
    @sites = Site.where(:id => @posts.map(&:site_id)).to_a
  end
end
