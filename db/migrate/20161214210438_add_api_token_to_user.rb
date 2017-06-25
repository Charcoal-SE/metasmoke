# frozen_string_literal: true

class AddAPITokenToUser < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :api_token, :string
  end
end
