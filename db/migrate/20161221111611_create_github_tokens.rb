# frozen_string_literal: true

class CreateGithubTokens < ActiveRecord::Migration[5.0]
  def change
    create_table :github_tokens do |t|
      t.string :token
      t.datetime :expires

      t.timestamps
    end
  end
end
