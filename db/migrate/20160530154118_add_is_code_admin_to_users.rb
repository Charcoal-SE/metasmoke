# frozen_string_literal: true

class AddIsCodeAdminToUsers < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :is_code_admin, :boolean, default: false
  end
end
