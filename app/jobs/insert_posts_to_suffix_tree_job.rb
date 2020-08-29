# frozen_string_literal: true

class InsertPostsToSuffixTreeJob < ApplicationJob
  queue_as :default

  def perform(*post_ids)
    Rails.logger.info "Job started (#{DateTime.now}, +0s)"
    post_ids.flatten.each do |id|
      SuffixTreeHelper.insert_post id
    end
    Rails.logger.info "Job finished (#{DateTime.now})"
  end
end
