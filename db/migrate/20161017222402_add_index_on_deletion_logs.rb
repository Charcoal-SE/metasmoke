class AddIndexOnDeletionLogs < ActiveRecord::Migration[5.0]
  def change
    add_index :deletion_logs, :post_id, :name => 'post_id_ix'
  end
end
