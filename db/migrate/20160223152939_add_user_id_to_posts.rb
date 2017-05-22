# frozen_string_literal: true

class AddUserIdToPosts < ActiveRecord::Migration[4.2]
  def change
    add_column :posts, :stack_exchange_user_id, :integer
  end
end
