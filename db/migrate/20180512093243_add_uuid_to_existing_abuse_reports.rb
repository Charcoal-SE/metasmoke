# frozen_string_literal: true

class AddUuidToExistingAbuseReports < ActiveRecord::Migration[5.2]
  def change
    AbuseReport.all.each do |ar|
      ar.update uuid: SecureRandom.uuid
    end
  end
end
