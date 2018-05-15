# frozen_string_literal: true

class CreateReviewQueues < ActiveRecord::Migration[5.2]
  def change
    create_table :review_queues do |t|
      t.string :name
      t.string :privileges
      t.text :responses
      t.integer :reviews_per_item

      t.timestamps
    end
  end
end
