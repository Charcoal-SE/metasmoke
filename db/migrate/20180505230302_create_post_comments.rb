# frozen_string_literal: true

class CreatePostComments < ActiveRecord::Migration[5.2]
  def change
    create_table :post_comments do |t|
      t.references :post, foreign_key: true
      t.references :user, foreign_key: true
      t.text :text

      t.timestamps
    end
  end
end
