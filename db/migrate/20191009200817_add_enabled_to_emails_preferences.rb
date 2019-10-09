class AddEnabledToEmailsPreferences < ActiveRecord::Migration[5.2]
  def change
    add_column :emails_preferences, :enabled, :boolean, null: false, default: 0
  end
end
