# frozen_string_literal: true

class CreateInitialSiteSettings < ActiveRecord::Migration[5.2]
  def change
    SiteSetting.create(name: 'require_auth_all_pages', value_type: 'boolean', value: '0')
  end
end
