class DropTokenMigratedFromUsers < ActiveRecord::Migration[5.2]
  def change
    rename_column :users, :token_migrated, :token_migrated_legacy
  end
end
