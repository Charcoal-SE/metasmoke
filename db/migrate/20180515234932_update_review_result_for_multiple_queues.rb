# frozen_string_literal: true

class UpdateReviewResultForMultipleQueues < ActiveRecord::Migration[5.2]
  def change
    ReviewResult.all.delete_all # easier than the alternative of trying to create queues and items for them all
    add_reference :review_results, :review_item, index: true
    remove_column :review_results, :feedback_id
    remove_column :review_results, :post_id
  end
end
