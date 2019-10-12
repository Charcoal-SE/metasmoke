class FixEmailsAddressees < ActiveRecord::Migration[5.2]
  def change
    Emails::Preference.destroy_all
    Emails::Addressee.destroy_all
    add_index :emails_addressees, :email_address, unique: true
  end
end
