class AddIsCompletedToFlags < ActiveRecord::Migration[5.0]
  def change
    add_column :flags, :is_completed, :boolean, :default => false
  end
end
