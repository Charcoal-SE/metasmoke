# frozen_string_literal: true

class UpdatePostFeedbackCaches < ActiveRecord::Migration[5.0]
  def up
    posts = Post.where(id: Feedback.where("feedback_type LIKE '%naa%'").pluck(:post_id))
    posts.includes(:feedbacks).all.each(&:update_feedback_cache)
  end
end
