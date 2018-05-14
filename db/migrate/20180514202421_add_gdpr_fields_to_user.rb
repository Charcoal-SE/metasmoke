# frozen_string_literal: true

class AddGdprFieldsToUser < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :eu_resident, :boolean
    add_column :users, :privacy_accepted, :boolean
  end
end
