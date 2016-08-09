class AddStackExchangeAccountIdToUser < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :stack_exchange_account_id, :integer
  end
end
