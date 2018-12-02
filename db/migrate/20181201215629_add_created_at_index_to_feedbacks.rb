# frozen_string_literal: true

class AddCreatedAtIndexToFeedbacks < ActiveRecord::Migration[5.2]
  def change
    add_index :feedbacks, :created_at
  end
end
