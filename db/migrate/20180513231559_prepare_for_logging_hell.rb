# frozen_string_literal: true

class PrepareForLoggingHell < ActiveRecord::Migration[5.2]
  def change
    File.delete Rails.root.join('log/query_times.log')
    SiteSetting.create name: 'log_query_timings', value_type: 'boolean', value: 0
  end
end
