class CreateStatistics < ActiveRecord::Migration[5.0]
  def change
    create_table :statistics do |t|
      t.integer :posts_scanned
      t.integer :smoke_detector_id

      t.timestamps
    end
  end
end
