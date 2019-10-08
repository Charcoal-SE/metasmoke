class CreateEmailsPreferences < ActiveRecord::Migration[5.2]
  def change
    create_table :emails_preferences do |t|
      t.references :emails_type, foreign_key: true
      t.references :emails_addressee, foreign_key: true
      t.datetime :next
      t.integer :frequency

      t.timestamps
    end
  end
end
