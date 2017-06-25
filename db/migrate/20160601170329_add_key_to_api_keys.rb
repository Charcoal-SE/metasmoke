# frozen_string_literal: true

class AddKeyToAPIKeys < ActiveRecord::Migration[5.0]
  def change
    add_column :api_keys, :key, :string
  end
end
