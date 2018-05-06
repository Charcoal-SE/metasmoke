class RunCreateViewsAgain < ActiveRecord::Migration[5.2]
  def change
    success = system 'rails runner db/scripts/create_views.rb'
    raise StandardError, 'View script had non-zero exit code' unless success
  end
end
