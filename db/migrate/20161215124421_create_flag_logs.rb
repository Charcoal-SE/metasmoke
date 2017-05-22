# frozen_string_literal: true

class CreateFlagLogs < ActiveRecord::Migration[5.0]
  def change
    create_table :flag_logs do |t|
      t.boolean :success
      t.string :error_message
      t.references :flag_condition, foreign_key: true
      t.references :user, foreign_key: true
      t.references :post, foreign_key: true

      t.timestamps
    end
  end
end
