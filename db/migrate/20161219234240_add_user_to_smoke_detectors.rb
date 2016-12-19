class AddUserToSmokeDetectors < ActiveRecord::Migration[5.0]
  def change
    add_reference :smoke_detectors, :user, foreign_key: true
  end
end
