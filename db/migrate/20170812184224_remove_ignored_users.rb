# frozen_string_literal: true

class RemoveIgnoredUsers < ActiveRecord::Migration[5.1]
  def change
    remove_column :feedbacks, :is_ignored
    drop_table :ignored_users
  end
end
