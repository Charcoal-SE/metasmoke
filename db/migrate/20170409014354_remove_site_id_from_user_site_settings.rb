# frozen_string_literal: true

class RemoveSiteIdFromUserSiteSettings < ActiveRecord::Migration[5.1]
  def change
    remove_reference :user_site_settings, :site, foreign_key: true
  end
end
