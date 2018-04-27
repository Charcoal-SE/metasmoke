# frozen_string_literal: true

class RemoveRedundantSiteSettings < ActiveRecord::Migration[5.2]
  def change
    SiteSetting.find_by(name: 'core_threshold').destroy
    SiteSetting.find_by(name: 'core_time_period').destroy
  end
end
