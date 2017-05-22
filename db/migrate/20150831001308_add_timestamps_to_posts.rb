# frozen_string_literal: true

class AddTimestampsToPosts < ActiveRecord::Migration[4.2]
  def change
    change_table(:posts, &:timestamps)
  end
end
