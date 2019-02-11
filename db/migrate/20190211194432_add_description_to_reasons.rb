class AddDescriptionToReasons < ActiveRecord::Migration[5.2]
  def change
    add_column :reasons, :description, :text
  end
end
