# frozen_string_literal: true

class CreateQueryAverages < ActiveRecord::Migration[5.2]
  def change
    create_table :query_averages do |t|
      t.string :path, null: false
      t.bigint :counter, default: 0, null: false
      t.decimal :average, default: 0, null: false, precision: 14, scale: 3
    end
  end
end
