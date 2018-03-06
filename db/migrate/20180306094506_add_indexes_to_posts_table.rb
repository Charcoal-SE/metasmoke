class AddIndexesToPostsTable < ActiveRecord::Migration[5.2]
  def change
    add_index :posts, :is_tp
    add_index :posts, :is_fp
    add_index :posts, :is_naa
  end
end
