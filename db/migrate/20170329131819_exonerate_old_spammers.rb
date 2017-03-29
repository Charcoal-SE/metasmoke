class ExonerateOldSpammers < ActiveRecord::Migration[5.1]
  def change
    StackExchangeUser.where('id < 51476').update_all(:still_alive => false)
  end
end
