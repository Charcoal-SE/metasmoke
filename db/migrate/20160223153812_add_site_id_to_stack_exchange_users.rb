class AddSiteIdToStackExchangeUsers < ActiveRecord::Migration
  def change
    add_column :stack_exchange_users, :site_id, :integer
  end
end
