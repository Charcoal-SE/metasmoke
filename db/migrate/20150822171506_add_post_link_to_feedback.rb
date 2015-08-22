class AddPostLinkToFeedback < ActiveRecord::Migration
  def change
    add_column :feedbacks, :post_link, :string
  end
end
