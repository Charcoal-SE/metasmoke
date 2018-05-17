# frozen_string_literal: true

class ReviewItem < ApplicationRecord
  belongs_to :user
  belongs_to :queue, class_name: 'ReviewQueue', foreign_key: 'review_queue_id'
  belongs_to :reviewable, polymorphic: true
  has_many :results, class_name: 'ReviewResult'

  validates :reviewable_type, inclusion: { in: ['Post'] }

  scope(:active, -> { where(completed: false) })
  scope(:completed, -> { where(completed: true) })

  def self.unreviewed_by(queue, user)
    joins("LEFT JOIN review_results rr ON rr.review_item_id = review_items.id AND rr.user_id = #{user.id}").where(review_items: { queue: queue,
                                                                                                                                  completed: false },
                                                                                                                  rr: { id: nil })
  end
end
