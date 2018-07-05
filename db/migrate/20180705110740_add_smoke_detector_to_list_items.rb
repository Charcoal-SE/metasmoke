class AddSmokeDetectorToListItems < ActiveRecord::Migration[5.2]
  def change
    add_reference :list_items, :smoke_detector, foreign_key: true
  end
end
