# frozen_string_literal: true

class AddUncertaintyToDeletionLogs < ActiveRecord::Migration[5.2]
  def change
    add_column :deletion_logs, :uncertainty, :integer
  end
end
