# frozen_string_literal: true

class CreateDumps < ActiveRecord::Migration[5.2]
  def change
    create_table :dumps do |t|
      t.attachment :file
      t.timestamps
    end
  end
end
