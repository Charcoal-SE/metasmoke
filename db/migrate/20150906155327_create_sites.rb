class CreateSites < ActiveRecord::Migration
  def change
    create_table :sites do |t|
      t.string :site_name
      t.string :site_url
      t.string :site_logo
      t.string :site_domain

      t.timestamps null: false
    end
  end
end
