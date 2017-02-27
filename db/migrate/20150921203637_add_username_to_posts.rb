class AddUsernameToPosts < ActiveRecord::Migration[4.2]
  def change
    add_column :posts, :username, :string
  end
end
