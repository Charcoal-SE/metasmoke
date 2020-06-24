class AddMarkdownToPosts < ActiveRecord::Migration[5.2]
  def change
    add_column :posts, :markdown, :text, limit: 65535, null: true
  end
end
