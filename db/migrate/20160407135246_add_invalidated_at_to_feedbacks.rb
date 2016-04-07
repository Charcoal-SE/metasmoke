class AddInvalidatedAtToFeedbacks < ActiveRecord::Migration[5.0]
  def change
    add_column :feedbacks, :invalidated_at, :datetime
  end
end
