# frozen_string_literal: true

class AddAutoFlaggerSiteSetting < ActiveRecord::Migration[5.2]
  def change
    SiteSetting.create name: 'auto_flagger_role', value_type: 'boolean', value: '1'
  end
end
