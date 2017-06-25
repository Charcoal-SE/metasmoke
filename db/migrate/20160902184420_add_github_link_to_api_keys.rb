# frozen_string_literal: true

class AddGithubLinkToAPIKeys < ActiveRecord::Migration[5.0]
  def change
    add_column :api_keys, :github_link, :string
  end
end
