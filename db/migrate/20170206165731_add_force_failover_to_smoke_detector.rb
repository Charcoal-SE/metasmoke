class AddForceFailoverToSmokeDetector < ActiveRecord::Migration[5.0]
  def change
    add_column :smoke_detectors, :force_failover, :boolean, default: false
  end
end
