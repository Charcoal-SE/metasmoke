# frozen_string_literal: true

class AddPropertyToFlagLogs < ActiveRecord::Migration[5.1]
  def change
    add_column :flag_logs, :is_auto, :boolean, default: true
  end
end
