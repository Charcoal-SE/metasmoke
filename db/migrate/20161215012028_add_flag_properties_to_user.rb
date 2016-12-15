class AddFlagPropertiesToUser < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :flags_enabled, :boolean, :default => false
  end
end
