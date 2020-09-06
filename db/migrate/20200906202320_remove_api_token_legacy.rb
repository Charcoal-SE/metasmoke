# frozen_string_literal: true

class RemoveAPITokenLegacy < ActiveRecord::Migration[5.2]
  remove_column :users, :encrypted_api_token_legacy
  remove_column :users, :token_migrated_legacy
end
