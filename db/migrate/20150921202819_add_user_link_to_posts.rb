# frozen_string_literal: true

class AddUserLinkToPosts < ActiveRecord::Migration[4.2]
  def change
    add_column :posts, :user_link, :string
  end
end
