class CreateSmokeDetectors < ActiveRecord::Migration[4.2]
  def change
    create_table :smoke_detectors do |t|
      t.datetime :last_ping
      t.string :name
      t.string :location
      t.string :access_token

      t.timestamps null: false
    end
  end
end
