# frozen_string_literal: true

class ReviewItem < ApplicationRecord
  include Websocket

  belongs_to :user
  belongs_to :queue, class_name: 'ReviewQueue', foreign_key: 'review_queue_id'
  belongs_to :reviewable, polymorphic: true
  has_many :results, class_name: 'ReviewResult'

  [:post, :spam_domain, :flag].each do |t|
    belongs_to(t, -> { where(review_items: { reviewable_type: t.to_s.pluralize.classify }) }, foreign_key: 'reviewable_id')

    define_method t do
      return unless reviewable_type == t.to_s.classify
      super
    end
  end

  validates :reviewable_type, inclusion: { in: %w[Post SpamDomain Flag] }

  scope(:active, -> { where(completed: false) })
  scope(:completed, -> { where(completed: true) })

  def self.unreviewed_by(queue, user)
    joins("LEFT JOIN review_results rr ON rr.review_item_id = review_items.id AND rr.user_id = #{user.id}").where(review_items: { queue: queue,
                                                                                                                                  completed: false },
                                                                                                                  rr: { id: nil })
  end
end
