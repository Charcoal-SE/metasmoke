class CreateFeedback < ActiveRecord::Migration
  def change
    create_table :feedbacks do |t|
        t.string :message_link
        t.string :user_name
        t.string :user_link
        t.string :feedback_type
        t.belongs_to :post, index: true
    end
  end
end
