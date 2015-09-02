class AddLastPostTitleToReason < ActiveRecord::Migration
  def change
    add_column :reasons, :last_post_title, :string
  end
end
