class AddReferencedObjectToEmailsPreferences < ActiveRecord::Migration[5.2]
  def change
    add_reference :emails_preferences, :reference, polymorphic: true
  end
end
