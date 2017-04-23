class AddSmokeDetectorIdToPost < ActiveRecord::Migration[5.1]
  def change
    add_column :posts, :smoke_detector_id, :integer
  end
end
