class AddNeedsAdminAndReasonToPosts < ActiveRecord::Migration[5.0]
  def change
    add_column :posts, :needs_admin, :boolean, default: false
    add_column :posts, :admin_reason, :string
  end
end
