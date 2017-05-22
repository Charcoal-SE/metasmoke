# frozen_string_literal: true

class AddIndexOnCreationDateToPosts < ActiveRecord::Migration[5.0]
  def change
    add_index :posts, :created_at
  end
end
