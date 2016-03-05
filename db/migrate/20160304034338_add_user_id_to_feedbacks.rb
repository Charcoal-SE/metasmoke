class AddUserIdToFeedbacks < ActiveRecord::Migration
  def change
    add_column :feedbacks, :user_id, :integer
  end
end
