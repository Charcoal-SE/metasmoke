class FixRoleName < ActiveRecord::Migration[5.2]
  def change
    Role.where(name: 'code_admin').update(name: 'blacklist_manager')
  end
end
