# frozen_string_literal: true

class AddApiTokenToUser < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :api_token, :string
  end
end
