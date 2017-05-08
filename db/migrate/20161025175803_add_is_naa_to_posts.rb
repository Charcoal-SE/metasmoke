class AddIsNaaToPosts < ActiveRecord::Migration[5.0]
  def change
    add_column :posts, :is_naa, :boolean, default: false
  end
end
