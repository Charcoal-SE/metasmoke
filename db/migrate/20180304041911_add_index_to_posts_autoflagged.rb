class AddIndexToPostsAutoflagged < ActiveRecord::Migration[5.2]
  def change
    add_index :posts, :autoflagged
  end
end
