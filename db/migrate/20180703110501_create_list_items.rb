class CreateListItems < ActiveRecord::Migration[5.2]
  def change
    create_table :list_items do |t|
      t.references :list_type, foreign_key: true
      t.references :user, foreign_key: true
      t.text :data

      t.timestamps
    end
  end
end
