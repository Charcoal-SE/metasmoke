class AddSiteIdToStackExchangeUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :stack_exchange_users, :site_id, :integer
  end
end
