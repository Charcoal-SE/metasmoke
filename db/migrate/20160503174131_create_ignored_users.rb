# frozen_string_literal: true

class CreateIgnoredUsers < ActiveRecord::Migration[5.0]
  def change
    create_table :ignored_users do |t|
      t.string :user_name
      t.references :user, foreign_key: true

      t.timestamps
    end
  end
end
