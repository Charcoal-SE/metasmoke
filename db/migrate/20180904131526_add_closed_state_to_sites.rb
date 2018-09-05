# frozen_string_literal: true

class AddClosedStateToSites < ActiveRecord::Migration[5.2]
  def change
    add_column :sites, :closed, :boolean, default: false, null: false
  end
end
