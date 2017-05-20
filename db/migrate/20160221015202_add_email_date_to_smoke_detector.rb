# frozen_string_literal: true

class AddEmailDateToSmokeDetector < ActiveRecord::Migration[4.2]
  def change
    add_column :smoke_detectors, :email_date, :datetime
  end
end
