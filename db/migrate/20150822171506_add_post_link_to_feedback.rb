class AddPostLinkToFeedback < ActiveRecord::Migration[4.2]
  def change
    add_column :feedbacks, :post_link, :string
  end
end
