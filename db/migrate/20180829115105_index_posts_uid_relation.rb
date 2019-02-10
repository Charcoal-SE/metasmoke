# frozen_string_literal: true

class IndexPostsUidRelation < ActiveRecord::Migration[5.2]
  def change
    add_index :posts, %i[site_id native_id]
    add_index :sites, :api_parameter
  end
end
