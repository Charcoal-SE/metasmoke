class AddAutoDisputedFlagsEnabledToSites < ActiveRecord::Migration[5.2]
  def change
    add_column :sites, :auto_disputed_flags_enabled, :boolean
  end
end
