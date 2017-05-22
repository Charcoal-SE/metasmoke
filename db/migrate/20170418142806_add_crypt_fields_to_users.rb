# frozen_string_literal: true

class AddCryptFieldsToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :salt, :binary
    add_column :users, :iv, :binary
  end
end
