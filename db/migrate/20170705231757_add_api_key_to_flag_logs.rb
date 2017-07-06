# frozen_string_literal: true

class AddAPIKeyToFlagLogs < ActiveRecord::Migration[5.1]
  def change
    add_reference :flag_logs, :api_key, foreign_key: true, type: :integer
  end
end
