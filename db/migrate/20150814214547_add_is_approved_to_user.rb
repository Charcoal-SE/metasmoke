class AddIsApprovedToUser < ActiveRecord::Migration
  def change
    add_column :users, :is_approved, :bool
  end
end
