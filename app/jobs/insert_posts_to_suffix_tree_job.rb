# frozen_string_literal: true

class InsertPostsToSuffixTreeJob < ApplicationJob
  queue_as :default

  def perform(*post_ids)
    post_ids.flatten.each do |id|
      SuffixTreeHelper.insert_post id
    end
  end
end
