# frozen_string_literal: true

class CreateSitesUserSiteSettingsJoinTable < ActiveRecord::Migration[5.0]
  def change
    create_table 'sites_user_site_settings' do |t|
      t.integer :site_id
      t.integer :user_site_setting_id
    end
  end
end
