# frozen_string_literal: true

class AddSiteSettings < ActiveRecord::Migration[5.2]
  def change
    SiteSetting.create name: 'registration_enabled', value_type: 'boolean', value: 1
    SiteSetting.create name: 'new_account_messages_enabled', value_type: 'boolean', value: 1
    SiteSetting.create name: 'make_trolls_lives_hard', value_type: 'boolean', value: 0
  end
end
