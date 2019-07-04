# frozen_string_literal: true

class ReviewQueue < ApplicationRecord
  include Websocket

  has_many :items, class_name: 'ReviewItem'
  has_many :results, class_name: 'ReviewResult', through: :items

  serialize :responses, JSON

  def self.[](key)
    find_by name: key
  end

  def should_dq?(item)
    item.reviewable.should_dq?(self) if item.reviewable.respond_to? :should_dq?
    false
  end

  def next_items(user)
    unreviewed_by = ReviewItem.unreviewed_by(self, user)
    if block_given?
      unreviewed_by = yield unreviewed_by
    end
    unreviewed_by
  end
end
