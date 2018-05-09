# frozen_string_literal: true

class RemoveOrderingFromAbuseReportStatuses < ActiveRecord::Migration[5.2]
  def change
    remove_column :abuse_report_statuses, :ordering, :integer
  end
end
