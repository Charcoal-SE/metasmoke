class CreateSpamWaves < ActiveRecord::Migration[5.2]
  def change
    create_table :spam_waves do |t|
      t.string :name
      t.text :conditions
      t.references :user, foreign_key: true
      t.datetime :expiry
      t.integer :max_flags

      t.timestamps
    end
  end
end
