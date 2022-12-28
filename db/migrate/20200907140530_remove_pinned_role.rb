# frozen_string_literal: true

class RemovePinnedRole < ActiveRecord::Migration[5.2]
  def change
    remove_column :users_roles, :pinned
  end
end
