# frozen_string_literal: true

class CreateAbuseContacts < ActiveRecord::Migration[5.2]
  def change
    create_table :abuse_contacts do |t|
      t.string :name
      t.string :email
      t.string :link
      t.text :details

      t.timestamps
    end
  end
end
