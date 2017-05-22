# frozen_string_literal: true

class AddInvalidatedByToFeedback < ActiveRecord::Migration[5.0]
  def change
    add_column :feedbacks, :invalidated_by, :integer
  end
end
