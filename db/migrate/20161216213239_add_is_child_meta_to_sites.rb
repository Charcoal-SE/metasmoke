# frozen_string_literal: true

class AddIsChildMetaToSites < ActiveRecord::Migration[5.0]
  def change
    add_column :sites, :is_child_meta, :boolean
    SitesHelper.updateSites
  end
end
