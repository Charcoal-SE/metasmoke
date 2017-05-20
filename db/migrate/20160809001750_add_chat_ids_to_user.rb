# frozen_string_literal: true

class AddChatIdsToUser < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :stackexchange_chat_id, :integer
    add_column :users, :meta_stackexchange_chat_id, :integer
    add_column :users, :stackoverflow_chat_id, :integer
  end
end
