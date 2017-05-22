# frozen_string_literal: true

class RemoveLegacyPermissionsAttributes < ActiveRecord::Migration[5.0]
  def change
    remove_column :users, :is_approved
    remove_column :users, :is_admin
    remove_column :users, :is_code_admin
  end
end
