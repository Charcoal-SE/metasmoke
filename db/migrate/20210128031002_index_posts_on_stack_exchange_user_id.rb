# frozen_string_literal: true
class IndexPostsOnStackExchangeUserId < ActiveRecord::Migration[5.2]
  def change
    add_index :posts, :stack_exchange_user_id
  end
end
