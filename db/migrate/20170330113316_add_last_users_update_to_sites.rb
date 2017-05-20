# frozen_string_literal: true

class AddLastUsersUpdateToSites < ActiveRecord::Migration[5.1]
  def change
    add_column :sites, :last_users_update, :datetime
  end
end
