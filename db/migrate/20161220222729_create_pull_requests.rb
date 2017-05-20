# frozen_string_literal: true

class CreatePullRequests < ActiveRecord::Migration[5.0]
  def change
    create_table :pull_requests do |t|
      t.boolean :has_review
      t.string :last_commit_sha

      t.timestamps
    end
  end
end
