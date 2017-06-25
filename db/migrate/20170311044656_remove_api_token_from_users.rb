# frozen_string_literal: true

class RemoveAPITokenFromUsers < ActiveRecord::Migration[5.1]
  def change
    remove_column :users, :api_token
  end
end
