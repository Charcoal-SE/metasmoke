# frozen_string_literal: true

class AddIsApprovedToUser < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :is_approved, :bool
  end
end
