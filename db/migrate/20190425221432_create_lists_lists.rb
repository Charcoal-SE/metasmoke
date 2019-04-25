class CreateListsLists < ActiveRecord::Migration[5.2]
  def change
    create_table :lists_lists do |t|
      t.string :name
      t.text :description
      t.string :write_privs
      t.string :manage_privs

      t.timestamps
    end
  end
end
