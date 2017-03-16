class RemoveApiTokenFromUsers < ActiveRecord::Migration[5.1]
  def change
    remove_column :users, :api_token
  end
end
