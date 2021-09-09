# frozen_string_literal: true

class RecheckReviewQueueJob < ApplicationJob
  queue_as :default

  def perform(queue)
    queue.items.includes(:reviewable).each do |i|
      i.update(completed: true) if i.reviewable.should_dq?(queue)
    end
  end
end
