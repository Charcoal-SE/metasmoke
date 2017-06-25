# frozen_string_literal: true

class AddAppNameToAPIKeys < ActiveRecord::Migration[5.0]
  def change
    add_column :api_keys, :app_name, :string
  end
end
