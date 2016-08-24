class AddExpiryToApiTokens < ActiveRecord::Migration[5.0]
  def change
    add_column :api_tokens, :expiry, :timestamp
  end
end
