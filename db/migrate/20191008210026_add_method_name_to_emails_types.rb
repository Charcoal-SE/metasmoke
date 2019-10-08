class AddMethodNameToEmailsTypes < ActiveRecord::Migration[5.2]
  def change
    add_column :emails_types, :method_name, :string
  end
end
