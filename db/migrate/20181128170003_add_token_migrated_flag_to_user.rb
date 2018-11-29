# frozen_string_literal: true

class AddTokenMigratedFlagToUser < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :token_migrated, :bool, default: false, null: false
  end
end
