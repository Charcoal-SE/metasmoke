class AddIsTrustedToApiKeys < ActiveRecord::Migration[5.1]
  def change
    add_column :api_keys, :is_trusted, :boolean
  end
end
