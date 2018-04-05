class CreateChannelsUsers < ActiveRecord::Migration[5.2]
  def change
    create_table :channels_users do |t|
      t.references :user, foreign_key: true
      t.string :secret
      t.string :link

      t.timestamps
    end
  end
end
