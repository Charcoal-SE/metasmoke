# frozen_string_literal: true

class UpdateAllFeedbackCaches < ActiveRecord::Migration[5.2]
  def change
    Post.all.each(&:update_feedback_cache)
  end
end
