class RedisLogJob < ApplicationJob
  queue_as :default

  def perform(request_id, timestamp)
    redis = redis(logger: true)
    info = redis.hgetall("request/#{timestamp}/#{request_id}").merge({
      headers: redis.hgetall("request/#{timestamp}/#{request_id}/headers"),
      params: redis.hgetall("request/#{timestamp}/#{request_id}/params"),
      exception: redis.hgetall("request/#{timestamp}/#{request_id}/exception"),
      timestamp: timestamp,
      request_id: request_id,
      key: "#{timestamp.to_s.gsub('.', '-')}-#{request_id}"
    })
    ActionCable.server.broadcast "redis_log_channel", key: "#{timestamp.to_s.gsub('.', '-')}-#{request_id}",
                                                      html: ApplicationController.render(
                                                        template: 'redis_log/_row',
                                                        locals: { req: info, wrapped: true },
                                                        layout: nil
                                                      )
  end
end
