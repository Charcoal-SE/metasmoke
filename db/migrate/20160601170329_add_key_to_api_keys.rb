# frozen_string_literal: true

class AddKeyToApiKeys < ActiveRecord::Migration[5.0]
  def change
    add_column :api_keys, :key, :string
  end
end
