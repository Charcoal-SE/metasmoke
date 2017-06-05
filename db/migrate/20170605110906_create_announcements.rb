# frozen_string_literal: true

class CreateAnnouncements < ActiveRecord::Migration[5.1]
  def change
    create_table :announcements do |t|
      t.string :text
      t.datetime :expiry

      t.timestamps
    end
  end
end
