class RemoveBlacklistedWebsites < ActiveRecord::Migration[5.0]
  def change
    drop_table :blacklisted_websites
  end
end
