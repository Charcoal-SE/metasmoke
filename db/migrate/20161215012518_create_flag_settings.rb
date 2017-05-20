# frozen_string_literal: true

class CreateFlagSettings < ActiveRecord::Migration[5.0]
  def change
    create_table :flag_settings do |t|
      t.string :name
      t.string :value

      t.timestamps
    end
  end
end
