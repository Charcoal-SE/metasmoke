# frozen_string_literal: true

class CreateAbuseComments < ActiveRecord::Migration[5.2]
  def change
    create_table :abuse_comments do |t|
      t.references :user, foreign_key: true
      t.references :abuse_report, foreign_key: true
      t.text :text

      t.timestamps
    end
  end
end
