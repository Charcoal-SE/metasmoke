# frozen_string_literal: true

class AddUserIdToFeedbacks < ActiveRecord::Migration[4.2]
  def change
    add_column :feedbacks, :user_id, :integer
  end
end
