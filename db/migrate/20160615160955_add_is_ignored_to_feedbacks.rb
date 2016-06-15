class AddIsIgnoredToFeedbacks < ActiveRecord::Migration[5.0]
  def change
    add_column :feedbacks, :is_ignored, :boolean
  end
end
