# frozen_string_literal: true

class FeedbackReindexJob < ApplicationJob
  queue_as :default

  def perform
    query_results = ActiveRecord::Base.connection.execute(File.read(Rails.root.join('lib/queries/incorrectly_indexed_feedback.sql').to_s)).to_a
    bad_ids = query_results.map(&:first).flatten
    reindexed_count = 0
    bad_ids.each do |pid|
      reindexed_count += Post.find(pid).update_feedback_cache ? 1 : 0
    end
    Rails.logger.info "Reindexed feedback for #{reindexed_count} posts"
  end
end
