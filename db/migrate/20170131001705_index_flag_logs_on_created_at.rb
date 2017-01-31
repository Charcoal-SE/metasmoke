class IndexFlagLogsOnCreatedAt < ActiveRecord::Migration[5.0]
  def change
    add_index :flag_logs, :created_at
  end
end
