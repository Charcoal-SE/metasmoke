# frozen_string_literal: true

class ReviewQueue < ApplicationRecord
  has_many :items, class_name: 'ReviewItem'
  has_many :results, class_name: 'ReviewResult', through: :items

  def self.[](key)
    find_by name: key
  end
end
