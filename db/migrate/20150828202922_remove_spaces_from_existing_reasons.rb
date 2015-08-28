class RemoveSpacesFromExistingReasons < ActiveRecord::Migration
  def change
    Reason.all.each do |reason|
      reason.reason_name = reason.reason_name.strip
      reason.save!
    end
  end
end
