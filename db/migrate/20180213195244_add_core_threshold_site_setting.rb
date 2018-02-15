class AddCoreThresholdSiteSetting < ActiveRecord::Migration[5.2]
  def change
    SiteSetting.create(name: 'core_threshold', value_type: 'number', value: '60')
  end
end
