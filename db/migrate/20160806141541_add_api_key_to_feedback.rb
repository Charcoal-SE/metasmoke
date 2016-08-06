class AddApiKeyToFeedback < ActiveRecord::Migration[5.0]
  def change
    add_column :feedbacks, :api_key_id, :integer
  end
end
