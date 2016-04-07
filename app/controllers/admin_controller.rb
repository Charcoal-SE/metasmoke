class AdminController < ApplicationController
  before_filter :verify_admin

  def index
  end

  def recently_invalidated
    @feedbacks = Feedback.unscoped.joins('inner join posts on feedbacks.post_id = posts.id').where(:is_invalidated => true).select('posts.title, feedbacks.*').order('feedbacks.invalidated_at DESC')
  end

  def user_feedback
    begin
      @user = User.find_by_email params[:user_name]
      @feedbacks = Feedback.unscoped.joins('inner join posts on feedbacks.post_id = posts.id').where(:user_id => @user.id).select('posts.title, feedbacks.*').order('feedbacks.id DESC')
      @feedback_count = Feedback.unscoped.where(:user_id => @user.id).count
      @invalid_count = Feedback.unscoped.where(:user_id => @user.id, :is_invalidated => true).count
    rescue ActiveRecord::RecordNotFound
      @feedbacks = Feedback.unscoped.joins('inner join posts on feedbacks.post_id = posts.id').where(:user_name => params[:user_name]).select('posts.title, feedbacks.*').order('feedbacks.id DESC')
      @feedback_count = Feedback.unscoped.where(:user_name => params[:user_name]).count
      @invalid_count = Feedback.unscoped.where(:user_name => params[:user_name], :is_invalidated => true)
    end
  end
end
