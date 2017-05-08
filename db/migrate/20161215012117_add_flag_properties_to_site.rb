class AddFlagPropertiesToSite < ActiveRecord::Migration[5.0]
  def change
    add_column :sites, :flags_enabled, :boolean, default: false
    add_column :sites, :max_flags_per_post, :int, default: 1
  end
end
