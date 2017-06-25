# frozen_string_literal: true

class CreateAPITokens < ActiveRecord::Migration[5.0]
  def change
    create_table :api_tokens do |t|
      t.string :code
      t.references :api_key, foreign_key: true
      t.references :user, foreign_key: true
      t.string :token

      t.timestamps
    end
  end
end
