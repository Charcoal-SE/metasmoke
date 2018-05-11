# frozen_string_literal: true

class AddUuidToAbuseReports < ActiveRecord::Migration[5.2]
  def change
    add_column :abuse_reports, :uuid, :string
  end
end
