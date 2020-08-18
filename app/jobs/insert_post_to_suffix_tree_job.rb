# frozen_string_literal: true

class InsertPostToSuffixTreeJob < ApplicationJob
  queue_as :default

  def perform(post_id)
    Rails.logger.info "Job started (#{DateTime.now}, +0s)"
    SuffixTreeHelper.insert_post post_id
    SuffixTreeHelper.sync_async
    Rails.logger.info "Job finished (#{DateTime.now})"
  end
end
