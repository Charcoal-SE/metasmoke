# frozen_string_literal: true

class AddIsBlacklistManagerToUsers < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :is_blacklist_manager, :boolean, default: false
  end
end
