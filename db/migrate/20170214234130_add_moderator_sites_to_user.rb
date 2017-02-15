class AddModeratorSitesToUser < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :moderator_sites, :text
  end
end
