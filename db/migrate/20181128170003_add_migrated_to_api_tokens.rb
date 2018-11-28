class AddMigratedToAPITokens < ActiveRecord::Migration[5.2]
  def change
    add_column :api_tokens, :migrated, :bool, default: false, null: false
  end
end
