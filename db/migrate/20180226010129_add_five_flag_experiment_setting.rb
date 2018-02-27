# frozen_string_literal: true

class AddFiveFlagExperimentSetting < ActiveRecord::Migration[5.2]
  def change
    FlagSetting.create(
      name: 'five_flag_experiment_threshold',
      value: '10000'
    )
  end
end
