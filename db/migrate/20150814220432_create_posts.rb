class CreatePosts < ActiveRecord::Migration
  def change
    create_table :posts do |t|
      t.integer :reason_id
      t.string :title
      t.text :body
      t.string :link
      t.timestamp :catch_date
      t.string :result
      t.string :message_link
      t.string :message_user

      t.timestamps null: false
    end
  end
end
