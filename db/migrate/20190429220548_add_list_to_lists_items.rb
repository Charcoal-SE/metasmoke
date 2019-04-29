class AddListToListsItems < ActiveRecord::Migration[5.2]
  def change
    add_reference :lists_items, :lists_list, foreign_key: true
  end
end
