# frozen_string_literal: true

class AddCompletedToReviewItems < ActiveRecord::Migration[5.2]
  def change
    add_column :review_items, :completed, :boolean
  end
end
