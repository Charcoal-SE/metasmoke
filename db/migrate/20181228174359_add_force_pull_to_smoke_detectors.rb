class AddForcePullToSmokeDetectors < ActiveRecord::Migration[5.2]
  def change
    add_column :smoke_detectors, :force_pull, :boolean, default: false
  end
end
