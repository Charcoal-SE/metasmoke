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
    @user = User.all.where(:id => params[:user_id]).first
    @feedback = Feedback.unscoped.joins('inner join posts on feedbacks.post_id = posts.id').where(:user_id => @user.id).select('posts.title, feedbacks.*')
    @sources = ['metasmoke']

    if @user.stackoverflow_chat_id.present?
      @sources << 'Stack Overflow chat'
    end

    if @user.stackexchange_chat_id.present?
      @sources << 'Stack Exchange chat'
    end

    if @user.meta_stackexchange_chat_id.present?
      @sources << 'Meta Stack Exchange chat'
    end

    @feedback = @feedback.order('feedbacks.id DESC').paginate(:page => params[:page], :per_page => 100)
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
    @users = User.all.includes(:roles).paginate(:page => params[:page], :per_page => 50)
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

  def api_feedback
    @feedback = Feedback.via_api.includes(:user, :post).order(:created_at => :desc).paginate(:page => params[:page], :per_page => 100)
  end

  def permissions
    @roles = Role.names
    @users = User.all.paginate(:page => params[:page], :per_page => 100).preload(:roles)
  end

  def update_permissions
    if params["permitted"] == 'true'
      if params["role"] == 'developer'
        render :nothing => true, :status => :forbidden
        return
      end
      User.find(params["user_id"]).add_role params["role"]
    else
      User.find(params["user_id"]).remove_role params["role"]
    end

    render :nothing => true, :status => :accepted
  end

  private
    def set_ignored_user
      @ignored = IgnoredUser.find params[:id]
    end
end
