# frozen_string_literal: true

class RemoveNeedsAdminAndReasonFromPosts < ActiveRecord::Migration[5.0]
  def change
    remove_column :posts, :needs_admin, :string
    remove_column :posts, :admin_reason, :string
  end
end
