# frozen_string_literal: true

class AddBackoffToFlagLog < ActiveRecord::Migration[5.0]
  def change
    add_column :flag_logs, :backoff, :integer
  end
end
