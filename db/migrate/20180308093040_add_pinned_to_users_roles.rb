class AddPinnedToUsersRoles < ActiveRecord::Migration[5.2]
  def change
    add_column :users_roles, :pinned, :boolean, default: false
  end
end
