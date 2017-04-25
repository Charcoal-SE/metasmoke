class AddApiKeyIdToDeletionLogs < ActiveRecord::Migration[5.1]
  def change
    add_column :deletion_logs, :api_key_id, :integer
  end
end
