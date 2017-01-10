class AddApiQuotaToStatistics < ActiveRecord::Migration[5.0]
  def change
    add_column :statistics, :api_quota, :integer
  end
end
