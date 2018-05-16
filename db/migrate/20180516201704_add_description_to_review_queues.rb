# frozen_string_literal: true

class AddDescriptionToReviewQueues < ActiveRecord::Migration[5.2]
  def change
    add_column :review_queues, :description, :text
  end
end
