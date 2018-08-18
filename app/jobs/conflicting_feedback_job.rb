# frozen_string_literal: true

class ConflictingFeedbackJob < ApplicationJob
  queue_as :default

  def perform
    conflicted = Post.where('created_at <= ?', 1.day.ago).where('is_tp = 1 AND (is_fp = 1 OR is_naa = 1)')
                     .includes(:feedbacks).map do |p|
      feedback_classes = p.feedbacks.map { |f| f.feedback_type[0] }
      unique_classes = feedback_classes.uniq
      feedback_counts = unique_classes.map { |fc| [fc, feedback_classes.count(fc)] }.to_h
      [p, feedback_counts]
    end.to_h

    # Magic number: minimum threshold to be automatically resolvable. One feedback class must outstrip another
    # by this amount for the conflict to be resolvable; otherwise, it's going to need more human eyes.
    resolvable = conflicted.select do |_post, feedback_counts|
      counts = feedback_counts.values
      counts.max >= counts.max(2)[1] + 2
    end

    resolvable.each do |post, feedback_counts|
      winner = feedback_counts.max_by { |_k, v| v }[0]
      post.feedbacks.where('LEFT(feedback_type, 1) != ?', winner).update_all(is_invalidated: true, invalidated_by: -1, invalidated_at: DateTime.now)
    end
  end
end
