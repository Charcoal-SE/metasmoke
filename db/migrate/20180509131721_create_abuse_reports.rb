# frozen_string_literal: true

class CreateAbuseReports < ActiveRecord::Migration[5.2]
  def change
    create_table :abuse_reports do |t|
      t.references :user, foreign_key: true
      t.references :reportable, polymorphic: true
      t.references :abuse_contact, foreign_key: true, null: true
      t.references :abuse_report_status, foreign_key: true, null: true
      t.text :details

      t.timestamps
    end
  end
end
