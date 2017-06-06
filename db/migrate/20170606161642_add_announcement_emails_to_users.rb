# frozen_string_literal: true

class AddAnnouncementEmailsToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :announcement_emails, :boolean
  end
end
