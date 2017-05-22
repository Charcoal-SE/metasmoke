# frozen_string_literal: true

class CreateDeletionLogs < ActiveRecord::Migration[5.0]
  def change
    create_table :deletion_logs do |t|
      t.integer :post_id
      t.boolean :is_deleted

      t.timestamps
    end
  end
end
