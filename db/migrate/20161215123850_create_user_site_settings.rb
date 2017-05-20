# frozen_string_literal: true

class CreateUserSiteSettings < ActiveRecord::Migration[5.0]
  def change
    create_table :user_site_settings do |t|
      t.integer :max_flags
      t.integer :flags_used
      t.references :user, foreign_key: true
      t.references :site, foreign_key: true

      t.timestamps
    end
  end
end
