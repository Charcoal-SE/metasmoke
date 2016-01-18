class AddWhyToPost < ActiveRecord::Migration
  def change
    add_column :posts, :why, :text
  end
end
