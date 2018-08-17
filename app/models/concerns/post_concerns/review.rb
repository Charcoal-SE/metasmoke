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
        feedbacks.count >= 2
      else
        false
      end
    end

    def review_item_name
      title
    end
  end
end
