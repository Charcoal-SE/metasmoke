# frozen_string_literal: true

class CreateModeratorSites < ActiveRecord::Migration[5.0]
  def change
    create_table :moderator_sites do |t|
      t.integer :user_id
      t.integer :site_id

      t.timestamps
    end
  end
end
