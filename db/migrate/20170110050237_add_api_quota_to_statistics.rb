# frozen_string_literal: true

class AddAPIQuotaToStatistics < ActiveRecord::Migration[5.0]
  def change
    add_column :statistics, :api_quota, :integer
  end
end
