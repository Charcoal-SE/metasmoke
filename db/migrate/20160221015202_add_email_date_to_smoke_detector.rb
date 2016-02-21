class AddEmailDateToSmokeDetector < ActiveRecord::Migration
  def change
    add_column :smoke_detectors, :email_date, :datetime
  end
end
