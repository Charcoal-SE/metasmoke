class AddUsernameToPosts < ActiveRecord::Migration
  def change
    add_column :posts, :username, :string
  end
end
