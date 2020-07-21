# frozen_string_literal: true

class AutoReviewJob < ApplicationJob
  queue_as :default
  
  def perform
    Rails.logger.info "Job started (#{DateTime.now})"

    # Post reported more than 1 month ago, has no true positive feedback, and is not deleted; probably not spam.
    old_posts = Post.where('created_at > ?', 1.month.ago).where(deleted_at: nil).where(is_tp: false)

    Rails.logger.warn "Found #{old_posts.count} posts auto-reviewable."
    err_counter = 0
    old_posts.each do |p|
      fb = Feedback.new(feedback_type: 'fp-',
                        user_id: -1, # SmokeDetector
                        post_id: p.id)

      if fb.save
        Rails.logger.warn "Successfully auto-reviewed #{p.id} as fp-"
      else
        Rails.logger.warn "Error when saving auto-review feedback 'fp-' on #{p.id}"
        err_counter += 1
      end
    end

    Rails.logger.warn "Auto-review finished, total #{old_posts.count} posts, #{err_counter} errors."
    Rails.logger.info "Job finished (#{DateTime.now})"
  end
end
