# frozen_string_literal: true

class CreateSites < ActiveRecord::Migration[4.2]
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
