class AddSiteToPost < ActiveRecord::Migration
  def change
    add_column :posts, :site_id, :integer
  end
end
