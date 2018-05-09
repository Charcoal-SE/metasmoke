# frozen_string_literal: true

class AddIconAndColorToAbuseReportStatuses < ActiveRecord::Migration[5.2]
  def change
    add_column :abuse_report_statuses, :icon, :string
    add_column :abuse_report_statuses, :color, :string
  end
end
