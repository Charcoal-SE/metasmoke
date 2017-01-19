class IndexFeedbacksOnUserName < ActiveRecord::Migration[5.0]
  def change
    add_index(:feedbacks, :user_name, name: 'by_user_name', length: 5)
  end
end
