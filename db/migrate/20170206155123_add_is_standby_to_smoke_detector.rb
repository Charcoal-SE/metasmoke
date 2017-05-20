# frozen_string_literal: true

class AddIsStandbyToSmokeDetector < ActiveRecord::Migration[5.0]
  def change
    add_column :smoke_detectors, :is_standby, :boolean, default: false
  end
end
