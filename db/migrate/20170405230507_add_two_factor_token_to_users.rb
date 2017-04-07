class AddTwoFactorTokenToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :two_factor_token, :string
  end
end
