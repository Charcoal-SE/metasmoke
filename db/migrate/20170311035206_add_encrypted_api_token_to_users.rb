# frozen_string_literal: true

class AddEncryptedApiTokenToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :encrypted_api_token, :string
  end
end
