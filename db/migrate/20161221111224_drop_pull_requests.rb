# frozen_string_literal: true

class DropPullRequests < ActiveRecord::Migration[5.0]
  def change
    drop_table :pull_requests
  end
end
