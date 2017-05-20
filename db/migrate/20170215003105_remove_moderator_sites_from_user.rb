# frozen_string_literal: true

class RemoveModeratorSitesFromUser < ActiveRecord::Migration[5.0]
  def change
    remove_column :users, :moderator_sites
  end
end
