class PopulateFeedbacksToRedis < ActiveRecord::Migration[5.2]
  def change
    Feedback.populate_redis_meta
  end
end
