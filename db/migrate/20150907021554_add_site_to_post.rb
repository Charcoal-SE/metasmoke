# frozen_string_literal: true

class AddSiteToPost < ActiveRecord::Migration[4.2]
  def change
    add_column :posts, :site_id, :integer
  end
end
