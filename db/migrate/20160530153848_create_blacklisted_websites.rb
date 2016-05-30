class CreateBlacklistedWebsites < ActiveRecord::Migration[5.0]
  def change
    create_table :blacklisted_websites do |t|
      t.string :host
      t.boolean :is_active

      t.timestamps
    end
  end
end
