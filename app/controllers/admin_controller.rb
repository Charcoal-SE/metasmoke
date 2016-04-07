class AdminController < ApplicationController
  before_filter :verify_admin

  def index
  end

  def recently_invalidated
    @feedbacks = Feedback.unscoped.joins('inner join posts on feedbacks.post_id = posts.id').where(:is_invalidated => true).select('posts.title, feedbacks.*').order('feedbacks.invalidated_at DESC')
  end

  def user_feedback
    @feedbacks = Feedback.unscoped.joins('inner join posts on feedbacks.post_id = posts.id').where(:user_name => params[:user_name]).select('posts.title, feedbacks.*').order('feedbacks.created_at DESC')
  end
end
