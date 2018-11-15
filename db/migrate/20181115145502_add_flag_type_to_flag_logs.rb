# frozen_string_literal: true

class AddFlagTypeToFlagLogs < ActiveRecord::Migration[5.2]
  def change
    add_column :flag_logs, :flag_type, :string, default: 'spam'
    add_column :flag_logs, :comment, :text
    add_index :flag_logs, :flag_type
  end
end
