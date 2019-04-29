class AddLinkFieldsToListsLists < ActiveRecord::Migration[5.2]
  def change
    add_column :lists_lists, :link_table, :string
    add_column :lists_lists, :link_field, :string
  end
end
