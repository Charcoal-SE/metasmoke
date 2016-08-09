class AdminController < ApplicationController
  before_action :verify_admin, :except => [:user_feedback, :api_feedback, :users, :recently_invalidated, :index]
  before_action :set_ignored_user, :only => [:ignore, :unignore, :destroy_ignored]

  def index
  end

  def recently_invalidated
    @feedbacks = Feedback.unscoped.joins('inner join posts on feedbacks.post_id = posts.id').where(:is_invalidated => true).select('posts.title, feedbacks.*').order('feedbacks.invalidated_at DESC').paginate(:page => params[:page], :per_page => 100)

    @users = User.where(:id => @feedbacks.pluck(:invalidated_by)).map { |u| [u.id, u] }.to_h
  end

  def user_feedback
    @user = User.all.where(:id => params[:user_id])
    ms_feedback = Feedback.unscoped.joins(:posts).where(:user_id => user.id)

    if user.stackoverflow_chat_id.present? && user.stackexchange_chat_id.present? && user.meta_stackexchange_chat_id.present?
      so_feedback = Feedback.unscoped.joins(:posts).where(:chat_host => "stackoverflow.com", :chat_user_id => user.stackoverflow_chat_id)
      se_feedback = Feedback.unscoped.joins(:posts).where(:chat_host => "stackexchange.com", :chat_user_id => user.stackexchange_chat_id)
      mse_feedback = Feedback.unscoped.joins(:posts).where(:chat_host => "meta.stackexchange.com", :chat_user_id => user.meta_stackexchange_chat_id)
      @feedback = ms_feedback.or(so_feedback).or(se_feedback).or(mse_feedback).order(:feedbacks => { :id => :desc }).paginate(:page => params[:page], :per_page => 100)
    else
      @ms_only = true
      @feedback = ms_feedback.order(:feedbacks => { :id => :desc }).paginate(:page => params[:page], :per_page => 100)
    end

    @feedback_count = @feedback.count
    @invalid_count = @feedback.where(:is_invalidated => true).count
  end

  def flagged
    @flags = Flag.where(:is_completed => false)
    @sites = Site.all.to_a
    @users = User.where(:id => @flags.pluck(:user_id))
  end

  def clear_flag
    f = Flag.find params[:id]
    f.is_completed = true

    if f.save
      render :plain => "OK"
    else
      render :plain => "Save failed.", :status => :internal_server_error
    end
  end

  def users
    @users = User.all
  end

  def ignored_users
    @ignored_users = IgnoredUser.all
  end

  def ignore
    @ignored.is_ignored = true
    @ignored.save
    redirect_to url_for(:controller => :admin, :action => :ignored_users)
  end

  def unignore
    @ignored.is_ignored = false
    @ignored.save
    redirect_to url_for(:controller => :admin, :action => :ignored_users)
  end

  def destroy_ignored
    @ignored.destroy
    redirect_to url_for(:controller => :admin, :action => :ignored_users)
  end

  def new_api_key
    @key = ApiKey.new
    @key.key = Digest::SHA256.hexdigest("#{rand(0..9e9)}#{Time.now}")
  end

  def create_api_key
    @key = ApiKey.new(key_params)
    @key.save!
    flash[:success] = "Successfully registered API key #{@key.key}"
    redirect_to url_for(:controller => :admin, :action => :new_api_key)
  end

  def key_list
    @keys = ApiKey.all
  end

  def api_feedback
    @feedback = Feedback.via_api.order(:created_at => :desc).paginate(:page => params[:page], :per_page => 100)
  end

  private
    def set_ignored_user
      @ignored = IgnoredUser.find params[:id]
    end

    def key_params
      params.require(:api_key).permit(:key, :app_name)
    end
end
