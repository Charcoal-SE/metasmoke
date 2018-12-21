class PopulateFeedbacksToRedis < ActiveRecord::Migration[5.2]
  def change
    # If this line isn't here, travis thinks we died
    ActiveRecord::Base.logger = Logger.new(STDOUT)
    Feedback.populate_redis_meta
  end
end
