# frozen_string_literal: true

class AddRevisionCountToPost < ActiveRecord::Migration[5.0]
  def change
    add_column :posts, :revision_count, :int
  end
end
