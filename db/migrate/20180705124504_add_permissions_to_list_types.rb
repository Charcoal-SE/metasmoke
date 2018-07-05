class AddPermissionsToListTypes < ActiveRecord::Migration[5.2]
  def change
    add_column :list_types, :permissions, :string
  end
end
