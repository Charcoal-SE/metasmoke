# frozen_string_literal: true

module PostConcerns::Review
  extend ActiveSupport::Concern

  included do
    scope(:unreviewed, -> { where('feedbacks_count < 2 or feedbacks_count is null') })

    after_commit do
      if review_item.present? && should_dq?(ReviewQueue['posts'])
        review_item.update(completed: true)
      end
    end

    def custom_review_action(_queue, _item, user, response)
      feedbacks.create(user: user, feedback_type: response)
    end

    def should_dq?(queue)
      case queue.name
      when 'posts'
        age_threshold = SiteSetting['review_old_posts_days_threshold']
        weight_threshold = SiteSetting['review_old_posts_weight_threshold']
        post_age = DateTime.now - created_at.to_datetime
        feedback_count = feedbacks.count
        feedback_types = feedbacks.map(&:feedback_type).uniq

        # Post has two feedbacks, OR has one or non-conflicting feedback and is old and low-weight
        feedback_count >= 2 ||
          ((feedback_count == 1 || feedback_types.size == 1) &&
            post_age >= age_threshold.days && total_weight <= weight_threshold)
      else
        false
      end
    end

    def review_item_name
      title
    end
  end
end
