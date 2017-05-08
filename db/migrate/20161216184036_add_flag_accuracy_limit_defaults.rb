class AddFlagAccuracyLimitDefaults < ActiveRecord::Migration[5.0]
  def change
    FlagSetting.create(
      name: 'min_accuracy',
      value: '99'
    )

    FlagSetting.create(
      name: 'min_post_count',
      value: '1000'
    )
  end
end
