class CreateEmailsAddressees < ActiveRecord::Migration[5.2]
  def change
    create_table :emails_addressees do |t|
      t.string :name
      t.string :email_address
      t.string :consent_via
      t.text :consent_comment
      t.string :manage_key

      t.timestamps
    end
  end
end
