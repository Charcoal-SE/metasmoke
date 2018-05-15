# frozen_string_literal: true

class ReviewItem < ApplicationRecord
  belongs_to :user
  belongs_to :review_queue
  belongs_to :reviewable, polymorphic: true
end
