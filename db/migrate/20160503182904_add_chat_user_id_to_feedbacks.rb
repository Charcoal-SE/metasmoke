# frozen_string_literal: true

class AddChatUserIdToFeedbacks < ActiveRecord::Migration[5.0]
  def change
    add_column :feedbacks, :chat_user_id, :integer
  end
end
