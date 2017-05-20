# frozen_string_literal: true

class AddUserToApiKeys < ActiveRecord::Migration[5.0]
  def change
    add_reference :api_keys, :user, foreign_key: true
  end
end
