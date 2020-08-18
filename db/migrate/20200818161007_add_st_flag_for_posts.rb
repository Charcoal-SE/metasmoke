class AddSTFlagForPosts < ActiveRecord::Migration[5.2]
  def change
    add_column :posts, :st_indexed, :boolean, default: false, null: false
  end
end
