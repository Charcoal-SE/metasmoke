# frozen_string_literal: true

class CreateAbuseReportStatuses < ActiveRecord::Migration[5.2]
  def change
    create_table :abuse_report_statuses do |t|
      t.string :name
      t.text :details
      t.integer :ordering

      t.timestamps
    end
  end
end
