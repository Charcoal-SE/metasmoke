class AddTypeToAPIKeys < ActiveRecord::Migration[5.2]
  def change
    add_column :api_keys, :key_type, :string, null: false, default: 'standard'
  end
end
