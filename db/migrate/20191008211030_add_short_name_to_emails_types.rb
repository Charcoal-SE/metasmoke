class AddShortNameToEmailsTypes < ActiveRecord::Migration[5.2]
  def change
    add_column :emails_types, :short_name, :string
  end
end
