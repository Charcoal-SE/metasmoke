class AddUserLinkToPosts < ActiveRecord::Migration
  def change
    add_column :posts, :user_link, :string
  end
end
