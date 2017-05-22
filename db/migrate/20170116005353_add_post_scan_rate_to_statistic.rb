# frozen_string_literal: true

class AddPostScanRateToStatistic < ActiveRecord::Migration[5.0]
  def change
    add_column :statistics, :post_scan_rate, :float
  end
end
