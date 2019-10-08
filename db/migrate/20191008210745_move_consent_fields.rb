class MoveConsentFields < ActiveRecord::Migration[5.2]
  def change
    remove_column :emails_addressees, :consent_via
    remove_column :emails_addressees, :consent_comment
    add_column :emails_preferences, :consent_via, :string, null: false
    add_column :emails_preferences, :consent_comment, :text
  end
end
