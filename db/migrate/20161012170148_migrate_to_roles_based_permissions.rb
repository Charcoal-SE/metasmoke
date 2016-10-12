class MigrateToRolesBasedPermissions < ActiveRecord::Migration[5.0]
  def up
    User.all.each do |u|
      u.add_role :reviewer if u.is_approved
      u.add_role :admin if u.is_admin
      u.add_role :code_admin if u.is_code_admin
    end
  end
  def down
    Role.destroy_all
  end
end
