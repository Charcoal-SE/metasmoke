# frozen_string_literal: true

class Flag < ApplicationRecord
  include Websocket

  belongs_to :post
  belongs_to :user, required: false

  after_create do
    ReviewItem.create queue: ReviewQueue['admin-flags'], reviewable: self, completed: false
  end

  def review_item_name
    "Flag on post #{post.id}, '#{post.title}'"
  end

  def custom_review_action(_queue, _item, _user, response)
    update(is_completed: true) if response == 'dismiss'
  end

  def should_dq?(_queue)
    is_completed?
  end
end
