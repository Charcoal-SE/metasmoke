# frozen_string_literal: true

class AddFulltextIndexToPostsBody < ActiveRecord::Migration[5.2]
  def change
    add_index :posts, :body, type: :fulltext
  end
end
