class AddIsInvalidatedToFeedbacks < ActiveRecord::Migration[5.0]
  def change
    add_column :feedbacks, :is_invalidated, :boolean, default: 0
  end
end
