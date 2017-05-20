# frozen_string_literal: true

class RemoveSpacesFromExistingReasons < ActiveRecord::Migration[4.2]
  def change
    Reason.all.each do |reason|
      reason.reason_name = reason.reason_name.strip
      reason.save!
    end
  end
end
