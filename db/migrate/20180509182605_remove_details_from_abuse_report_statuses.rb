# frozen_string_literal: true

class RemoveDetailsFromAbuseReportStatuses < ActiveRecord::Migration[5.2]
  def change
    remove_column :abuse_report_statuses, :details, :text
  end
end
