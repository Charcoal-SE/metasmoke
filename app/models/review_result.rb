# frozen_string_literal: true

class ReviewResult < ApplicationRecord
  include Websocket

  belongs_to :user
  belongs_to :item, class_name: 'ReviewItem', foreign_key: 'review_item_id'
end
