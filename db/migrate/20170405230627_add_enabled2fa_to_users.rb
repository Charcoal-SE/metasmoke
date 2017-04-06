class AddEnabled2faToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :enabled_2fa, :boolean
  end
end
