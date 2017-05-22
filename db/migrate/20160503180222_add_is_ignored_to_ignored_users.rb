# frozen_string_literal: true

class AddIsIgnoredToIgnoredUsers < ActiveRecord::Migration[5.0]
  def change
    add_column :ignored_users, :is_ignored, :boolean
  end
end
