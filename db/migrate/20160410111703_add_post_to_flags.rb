class AddPostToFlags < ActiveRecord::Migration[5.0]
  def change
    add_reference :flags, :post, foreign_key: true
  end
end
