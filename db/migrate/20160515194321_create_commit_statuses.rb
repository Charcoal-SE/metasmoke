# frozen_string_literal: true

class CreateCommitStatuses < ActiveRecord::Migration[5.0]
  def change
    create_table :commit_statuses do |t|
      t.string :commit_sha
      t.string :status
      t.string :commit_message

      t.timestamps
    end
  end
end
