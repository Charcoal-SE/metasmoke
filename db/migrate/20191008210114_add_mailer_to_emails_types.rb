class AddMailerToEmailsTypes < ActiveRecord::Migration[5.2]
  def change
    add_column :emails_types, :mailer, :string
  end
end
