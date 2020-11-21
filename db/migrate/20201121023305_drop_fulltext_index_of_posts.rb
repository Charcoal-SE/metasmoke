class DropFulltextIndexOfPosts < ActiveRecord::Migration[5.2]
  def change
    remove_index :posts, :body, type: :fulltext
  end
end
