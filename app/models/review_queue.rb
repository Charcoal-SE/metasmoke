# frozen_string_literal: true

class ReviewQueue < ApplicationRecord
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
end
