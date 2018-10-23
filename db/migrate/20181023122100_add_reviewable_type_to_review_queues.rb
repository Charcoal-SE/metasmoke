# frozen_string_literal: true

class AddReviewableTypeToReviewQueues < ActiveRecord::Migration[5.2]
  def change
    add_column :review_queues, :reviewable_type, :string

    ReviewQueue['posts'].update(reviewable_type: 'Post')
    ReviewQueue['untagged-domains'].update(reviewable_type: 'SpamDomain')
  end
end
