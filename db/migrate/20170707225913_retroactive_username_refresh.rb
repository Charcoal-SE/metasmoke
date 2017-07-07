class RetroactiveUsernameRefresh < ActiveRecord::Migration[5.1]
  def up
    User.where(username: ["1", "", nil]).each(&:get_username)
  end

  def down
  end
end
