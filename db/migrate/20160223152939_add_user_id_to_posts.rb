class AddUserIdToPosts < ActiveRecord::Migration
  def change
    add_column :posts, :stack_exchange_user_id, :integer
  end
end
