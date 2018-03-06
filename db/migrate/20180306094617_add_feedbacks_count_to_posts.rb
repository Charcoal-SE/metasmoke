class AddFeedbacksCountToPosts < ActiveRecord::Migration[5.2]
  def change
    add_column :posts, :feedbacks_count, :integer
    add_index :posts, :feedbacks_count
  end
end
