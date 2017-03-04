class RemoveUsernameUniqueIndex < ActiveRecord::Migration[5.1]
  def change
    remove_index :users, :username
  end
end
