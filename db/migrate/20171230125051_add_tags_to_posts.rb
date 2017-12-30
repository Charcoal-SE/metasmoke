class AddTagsToPosts < ActiveRecord::Migration[5.1]
  def change
    add_column :posts, :tags, :string
  end
end
