class AddCoreTimePeriodSiteSetting < ActiveRecord::Migration[5.2]
  def change
    SiteSetting.create(name: 'core_time_period', value_type: 'number', value: '30')
  end
end
