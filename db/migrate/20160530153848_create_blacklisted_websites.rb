class CreateBlacklistedWebsites < ActiveRecord::Migration[5.0]
  def change
    create_table :blacklisted_websites do |t|
      t.string :host
      t.boolean :is_active, :default => false

      t.timestamps
    end
  end
end
