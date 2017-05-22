# frozen_string_literal: true

class AddChatHostToFeedback < ActiveRecord::Migration[5.0]
  def change
    add_column :feedbacks, :chat_host, :string
  end
end
