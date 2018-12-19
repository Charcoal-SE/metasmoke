class AddWaveAccuracySiteSetting < ActiveRecord::Migration[5.2]
  def change
    SiteSetting.create name: 'min_wave_accuracy', value_type: 'float', value: '90.00'
    SiteSetting.create name: 'min_wave_post_count', value_type: 'number', value: '10'
  end
end
