# frozen_string_literal: true

REDIS_LOG_EXPIRATION = 1.day.seconds.to_i

def log_timestamps(ts, status:, action:, controller:, format:, method:, view_runtime:, db_runtime:, path:) # rubocop:disable Metrics/ParameterLists
  redis = redis(logger: true)
  redis.zadd "request_timings/view/by_path/#{method.upcase}/#{path}.#{format}", ts, view_runtime
  redis.zadd "request_timings/db/by_path/#{method.upcase}/#{path}.#{format}", ts, db_runtime
  redis.zadd "request_timings/total/by_path/#{method.upcase}/#{path}.#{format}", ts, (db_runtime + view_runtime)

  redis.zadd "request_timings/view/by_action/#{controller}##{action}", ts, view_runtime
  redis.zadd "request_timings/db/by_action/#{controller}##{action}", ts, db_runtime
  redis.zadd "request_timings/total/by_action/#{controller}##{action}", ts, (db_runtime + view_runtime)

  redis.zadd "request_timings/status_counts/by_path/#{method.upcase}/#{path}.#{format}", ts, status
  redis.zadd "request_timings/status_counts/by_action/#{controller}##{action}", ts, status
  redis.zadd 'request_timings/status_counts', ts, status

  redis.zadd 'request_timings/sha', ts, CurrentCommit, nx: true
end

ActiveSupport::Notifications.subscribe 'process_action.action_controller' do |_name, _started, _finished, _unique_id, data|
  redis = redis(logger: true)
  request_id = data[:headers]['action_dispatch.request_id']
  # redis_log_id = data[:headers]['rack.session']['redis_log_id']
  redis_log_key = data[:headers]['redis_logs.log_key']
  request_timestamp = data[:headers]['redis_logs.timestamp']
  unless request_timestamp.nil?
    redis.zadd "requests/status/#{data[:status] || 'INC'}", request_timestamp, request_id
    redis.mapped_hmset redis_log_key, data.slice(:controller, :action, :format, :method, :status, :view_runtime, :db_runtime)
    if data[:status] == 200
      log_timestamps(request_timestamp, **data.slice(
        :action, :controller,
        :view_runtime, :db_runtime,
        :method, :format, :status
      ), path: redis.hget(redis_log_key, 'path'))
    end
    redis.mapped_hmset "#{redis_log_key}/response_headers", data[:headers].to_h['action_controller.instance'].response.headers.to_h
    redis.expire "#{redis_log_key}/response_headers", REDIS_LOG_EXPIRATION
    if data[:exception].present?
      redis.hset redis_log_key, 'exception', data[:exception].join("\n")
      ex = data[:exception_object]
      redis.mapped_hmset "#{redis_log_key}/exception", file_name: ex.try(:file_name),
                                                       annotated_source_code: ex.try(:annoted_source_code)&.join("\n"),
                                                       line_number: ex.try(:line_number),
                                                       backtrace: ex.try(:backtrace)&.join("\n"),
                                                       message: ex.try(:message)
    end
    RedisLogJob.perform_later(request_id, request_timestamp)
  end
end

ActiveSupport::Notifications.subscribe 'endpoint_run.grape' do |_name, _started, _finished, _unique_id, data|
  redis = redis(logger: true)
  request_id = data[:env]['action_dispatch.request_id']
  # redis_log_id = data[:env]['rack.session']['redis_log_id']
  redis_log_key = data[:env]['redis_logs.log_key']
  request_timestamp = data[:env]['redis_logs.timestamp']
  # The API doesn't spit out that much, so I'm doing what I can
  redis.mapped_hmset redis_log_key, controller: nil,
                                    action: nil,
                                    format: data[:env]['api.endpoint'].headers['Content-Type'],
                                    method: data[:env]['grape.routing_args'][:route_info].request_method,
                                    status: 'API',
                                    view_runtime: nil,
                                    db_runtime: nil
  if data[:exception].present?
    redis.hset redis_log_key, 'exception', data[:exception].join("\n")
    ex = data[:exception_object]
    redis.mapped_hmset "#{redis_log_key}/exception", file_name: ex.try(:file_name),
                                                     annotated_source_code: ex.try(:annoted_source_code)&.join("\n"),
                                                     line_number: ex.try(:line_number),
                                                     backtrace: ex.try(:backtrace)&.join("\n"),
                                                     message: ex.try(:message)
  end
  RedisLogJob.perform_later(request_id, request_timestamp)
end
