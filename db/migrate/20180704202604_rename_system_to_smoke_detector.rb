class RenameSystemToSmokeDetector < ActiveRecord::Migration[5.2]
  def up
    User.where(id: -1)&.update_all(username: "SmokeDetector")
  end

  def down
    User.where(id: -1)&.update_all(username: "System")
  end
end
