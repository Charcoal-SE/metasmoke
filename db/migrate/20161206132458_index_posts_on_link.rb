class IndexPostsOnLink < ActiveRecord::Migration[5.0]
  def change
    add_index :posts, :link
  end
end
