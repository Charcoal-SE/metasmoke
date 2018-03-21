class RunCreateViews < ActiveRecord::Migration[5.2]
  def change
    success = system 'rails runner db/scripts/create_views.rb'
    unless success
      raise StandardError, 'View script had non-zero exit code'
    end
  end
end
