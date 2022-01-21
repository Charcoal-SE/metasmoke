# frozen_string_literal: true

class ReviewItem < ApplicationRecord
  include Websocket

  belongs_to :user
  belongs_to :queue, class_name: 'ReviewQueue', foreign_key: 'review_queue_id'
  belongs_to :reviewable, polymorphic: true
  has_many :results, class_name: 'ReviewResult'

  %i[post spam_domain flag].each do |t|
    belongs_to(t, lambda {
                    where(review_items: { reviewable_type: t.to_s.pluralize.classify })
                  }, foreign_key: 'reviewable_id')

    define_method t do
      return unless reviewable_type == t.to_s.classify

      super
    end
  end

  validates :reviewable_type, inclusion: { in: %w[Post SpamDomain Flag] }

  scope(:active, -> { where(completed: false) })
  scope(:completed, -> { where(completed: true) })

  after_save :populate_redis
  after_destroy :remove_from_redis

  def populate_redis
    redis.sadd 'review_queues', queue.id
    if completed
      redis.srem "review_queue/#{queue.id}/unreviewed", id
    else
      redis.sadd "review_queue/#{queue.id}/unreviewed", id
    end
  end

  def remove_from_redis(ri)
    redis.srem "review_queue/#{ri.queue.id}/unreviewed", ri.id
  end

  def self.populate_redis_meta
    eager_load(:queue).find_each(&:populate_redis)
  end

  def self.unreviewed_by(queue, user)
    if queue.name == 'posts'
      joins("LEFT JOIN review_results rr ON rr.review_item_id = review_items.id AND rr.user_id = #{user.id}")
        .joins("LEFT JOIN feedbacks f ON f.post_id = review_items.reviewable_id AND f.user_id = #{user.id}")
        .where(review_items: { queue: queue, completed: false }, rr: { id: nil }, f: { id: nil })
    else
      joins("LEFT JOIN review_results rr ON rr.review_item_id = review_items.id AND rr.user_id = #{user.id}")
        .where(review_items: { queue: queue, completed: false }, rr: { id: nil })
    end
  end
end
