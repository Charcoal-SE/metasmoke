# frozen_string_literal: true

class GivePeopleWithSmokeDetectorKeysAccessToManagementPage < ActiveRecord::Migration[5.1]
  def up
    SmokeDetector.all.map(&:user).compact.each { |u| u.add_role(:smoke_detector_runner) }
  end

  def down
    user.with_role(:smoke_detector_runner).each { |u| u.remove_role(:smoke_detector_runner) }
  end
end
