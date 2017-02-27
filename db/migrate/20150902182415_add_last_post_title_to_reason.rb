class AddLastPostTitleToReason < ActiveRecord::Migration[4.2]
  def change
    add_column :reasons, :last_post_title, :string
  end
end
