# frozen_string_literal: true

class AddIsDryRunToFlagLogs < ActiveRecord::Migration[5.0]
  def change
    add_column :flag_logs, :is_dry_run, :boolean
  end
end
