# frozen_string_literal: true

class CreateReviewItems < ActiveRecord::Migration[5.2]
  def change
    create_table :review_items do |t|
      t.references :review_queue, foreign_key: true
      t.references :reviewable, polymorphic: true

      t.timestamps
    end
  end
end
