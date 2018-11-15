# frozen_string_literal: true

class AddAutoDisputedFlagsEnabledToSites < ActiveRecord::Migration[5.2]
  def change
    add_column :sites, :auto_disputed_flags_enabled, :boolean, default: true
  end
end
