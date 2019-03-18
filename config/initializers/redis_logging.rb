# frozen_string_literal: true

require 'sensible_routes'

REDIS_LOG_EXPIRATION = 1.day.seconds.to_i

# rubocop:disable Metrics/ParameterLists
def log_timestamps(ts, status:, action:, controller:, format:, method:, view_runtime:, db_runtime:, path:, uuid:)
  # rubocop:enable Metrics/ParameterLists
  redis = redis(logger: true)
  return if path.nil?
  path = Rails.sensible_routes.match_for(path)&.path || path.split('?').first
  redis.zadd "request_timings/view/by_path/#{method.upcase}/#{path}.#{format}", ts, view_runtime
  redis.zadd "request_timings/db/by_path/#{method.upcase}/#{path}.#{format}", ts, db_runtime
  redis.zadd "request_timings/total/by_path/#{method.upcase}/#{path}.#{format}", ts, (db_runtime + view_runtime)

  redis.zadd "request_timings/view/by_action/#{controller}##{action}", ts, view_runtime
  redis.zadd "request_timings/db/by_action/#{controller}##{action}", ts, db_runtime
  redis.zadd "request_timings/total/by_action/#{controller}##{action}", ts, (db_runtime + view_runtime)

  redis.zadd "request_timings/status_counts/by_path/#{method.upcase}/#{path}.#{format}", ts, status
  redis.zadd "request_timings/status_counts/by_action/#{controller}##{action}", ts, status
  redis.zadd 'request_timings/status_counts', ts, status

  redis.zadd "requests/by_path/#{method.upcase}/#{path}.#{format}", ts, uuid
  redis.zadd "requests/by_action/#{controller}##{action}", ts, uuid

  redis.zadd 'request_timings/sha', ts, CurrentCommit, nx: true
end

ActiveSupport::Notifications.subscribe 'process_action.action_controller' do |_name, _started, _finished, _unique_id, data|
  redis = redis(logger: true)
  request_id = data[:headers]['action_dispatch.request_id']
  # redis_log_id = data[:headers]['rack.session']['redis_log_id']
  redis_log_key = data[:headers]['redis_logs.log_key']
  request_timestamp = data[:headers]['redis_logs.timestamp']
  unless request_timestamp.nil?
    RedisLogJob.perform_later(
      data.slice(:controller, :action, :format, :method, :status, :view_runtime, :db_runtime),
      subspaces: {
        response_headers: data[:headers].to_h['action_controller.instance'].response.headers.to_h
      },
      status: data[:status],
      exception: data.slice(:exception, :exception_object),
      time: request_timestamp,
      uuid: request_id,
      completed: true
    )
    if data[:status] == 200
      log_timestamps(request_timestamp, **data.slice(
        :action, :controller,
        :view_runtime, :db_runtime,
        :method, :format, :status
      ), path: redis.hget(redis_log_key, 'path'), uuid: request_id)
    end
  end
end

ActiveSupport::Notifications.subscribe 'endpoint_run.grape' do |_name, _started, _finished, _unique_id, data|
  request_id = data[:env]['action_dispatch.request_id']
  # redis_log_id = data[:env]['rack.session']['redis_log_id']
  request_timestamp = data[:env]['redis_logs.timestamp']

  RedisLogJob.perform_later(
    {
      # The API doesn't spit out that much, so I'm doing what I can
      controller: nil,
      action: nil,
      format: data[:env]['api.endpoint'].headers['Content-Type'],
      method: data[:env]['grape.routing_args'][:route_info].request_method,
      status: 'API',
      view_runtime: nil,
      db_runtime: Time.now.to_f - data[:env]['redis_logs.start_time'].to_f
    },
    exception: data.slice(:exception, :exception_object),
    time: request_timestamp,
    uuid: request_id,
    completed: true
  )
end
