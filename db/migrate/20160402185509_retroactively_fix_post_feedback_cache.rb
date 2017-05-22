# frozen_string_literal: true

class RetroactivelyFixPostFeedbackCache < ActiveRecord::Migration[4.2]
  def change
    Post.update_all(is_tp: false, is_fp: false)

    all_feedbacks = Feedback.all

    tp_posts = all_feedbacks.select(&:is_positive?).map(&:post_id).uniq

    fp_posts = all_feedbacks.select(&:is_negative?).map(&:post_id).uniq

    Post.where(id: tp_posts).update_all is_tp: true
    Post.where(id: fp_posts).update_all is_fp: true
  end
end
