class DropEncryptedAPITokenFromUsers < ActiveRecord::Migration[5.2]
  def change
    remove_column :users, :encrypted_api_token
  end
end
