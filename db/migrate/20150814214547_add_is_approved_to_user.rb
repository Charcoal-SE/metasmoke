class AddIsApprovedToUser < ActiveRecord::Migration[4.1]
  def change
    add_column :users, :is_approved, :bool
  end
end
