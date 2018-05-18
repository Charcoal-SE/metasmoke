# frozen_string_literal: true

class SpamDomain < ApplicationRecord
  include Websocket

  has_and_belongs_to_many :posts, after_add: :setup_review
  has_and_belongs_to_many :domain_tags, after_add: :check_dq
  has_one :review_item, as: :reviewable

  validates :domain, uniqueness: true

  def should_dq?(_item)
    domain_tags.count > 0
  end

  def review_item_name
    domain
  end

  private

  def setup_review(*_args)
    return unless posts.count >= 3 && domain_tags.count == 0 && !review_item.present?
    ReviewItem.create(reviewable: self, queue: ReviewQueue['untagged-domains'], completed: false)
  end

  def check_dq(*_args)
    return unless review_item.present? && should_dq?(review_item)
    review_item.update(completed: true)
  end
end
