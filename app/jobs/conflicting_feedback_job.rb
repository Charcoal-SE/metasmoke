# frozen_string_literal: true

class ConflictingFeedbackJob < ApplicationJob
  queue_as :default

  def perform
    Rails.logger.info "Job started (#{DateTime.now}, +0s)"

    conflicts = Post.where('created_at <= ?', 1.day.ago).where('is_tp = 1 AND (is_fp = 1 OR is_naa = 1)')\
                    .includes(:feedbacks, feedbacks: {user: :roles})
    Rails.logger.info "Total #{conflicts.count} existing conflicts."

    immediate_timer = Benchmark.measure do
      immediate_resolution_data = conflicts.map do |p|
        feedback_classes = p.feedbacks.map { |f| f.feedback_type[0] }
        unique_classes = feedback_classes.uniq
        feedback_counts = unique_classes.map { |fc| [fc, feedback_classes.count(fc)] }.to_h
        [p, feedback_counts]
      end.to_h

      # Magic number: minimum threshold to be immediately resolvable. One feedback class must outstrip another
      # by this amount for the conflict to be resolvable; otherwise, it's going to need more human eyes.
      resolvable = immediate_resolution_data.select do |_post, feedback_counts|
        counts = feedback_counts.values
        counts.max >= (counts.max(2)[1] || counts.max) + 2
      end

      Rails.logger.info "Found #{resolvable.size} immediately resolvable conflicts."

      resolvable.each do |post, feedback_counts|
        winner = feedback_counts.max_by { |_k, v| v }[0]
        post.feedbacks.where('LEFT(feedback_type, 1) != ?', winner).update_all(is_invalidated: true, invalidated_by: -1, invalidated_at: DateTime.now)
      end
    end

    detailed_timer = Benchmark.measure do
      # User precedences. Higher numbers mean a user possessing this role will override a user possessing a lower role.
      # Everyone gets flagger, so that's worth a whole nothing; developer likewise because you can be a developer without knowing anything about
      # feedback (and all of our current developers have other high-precedence roles as well).
      roles = { flagger: 0, reviewer: 1, core: 2, code_admin: 3, smoke_detector_runner: 3, admin: 4, developer: 0 }

      # One-liner beauty (or hell, depending how you look at it). First get a list of all feedbacks and the maximum precedence of the user who
      # created it. Secondly, take that list and uniq-ify it by summing all precedences for the same feedback type.
      detailed_resolution_data = conflicts.map do |p|
        feedback_data = p.feedbacks.map { |f| [f.feedback_type[0], (f.user&.roles&.map { |r| roles[r.name.to_sym] }&.max || 0)] }
        sums = feedback_data.map { |f| f[0] }.uniq.map { |ft| [ft, feedback_data.select { |f| f[0] == ft }.map { |f| f[1] }.sum] }
        [p, sums]
      end

      # If one feedback type has a higher total user precedence than any others, we can resolve the conflict to that feedback type.
      resolvable = detailed_resolution_data.select do |_post, feedback_data|
        values = feedback_data.map { |f| f[1] }
        values.max > (values.max(2)[1] || values.max)
      end

      Rails.logger.info "Found #{resolvable.size} further conflicts resolvable by user precedence."

      resolvable.each do |post, feedback_data|
        winner = feedback_data.max_by { |f| f[1] }[0]
        post.feedbacks.where('LEFT(feedback_type, 1) != ?', winner).update_all(is_invalidated: true, invalidated_by: -1, invalidated_at: DateTime.now)
      end
    end

    Rails.logger.info "Job finished (#{DateTime.now}, immediate=#{immediate_timer.real.round(2)}s, detailed=#{detailed_timer.real.round(2)}s)"
  end
end
