class ReviewQueueRecheckItemsJob < ApplicationJob
  queue_as :default

  def perform(queue_id)
    queue = Queue.find(queue_id)
    queue.items.includes(:reviewable).each do |i|
      i.update(completed: true) if i.reviewable.should_dq?(queue)
    end
  end
end
