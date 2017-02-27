class AddWhyToPost < ActiveRecord::Migration[4.2]
  def change
    add_column :posts, :why, :text
  end
end
