class CreateFlagConditions < ActiveRecord::Migration[5.0]
  def change
    create_table :flag_conditions do |t|
      t.boolean :flags_enabled
      t.integer :min_weight
      t.integer :max_poster_rep
      t.integer :min_reason_count
      t.references :user, foreign_key: true

      t.timestamps
    end
  end
end
