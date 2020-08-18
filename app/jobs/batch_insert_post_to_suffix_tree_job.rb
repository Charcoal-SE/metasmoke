class BatchInsertPostToSuffixTreeJob < ApplicationJob
  queue_as :default

  def perform(post_ids)
    Rails.logger.info "Job started (#{DateTime.now}, +0s)"
    post_ids.each do |id|
      SuffixTreeHelper::insert_post id
    end
    SuffixTreeHelper::sync_async
    Rails.logger.info "Job finished (#{DateTime.now})"
  end
end
