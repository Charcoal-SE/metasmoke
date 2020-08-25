# frozen_string_literal: true

require 'sensible_routes'

REDIS_LOG_EXPIRATION = 1.week.seconds.to_i

def sensible_routes_wrap(method, path)
  Rails.application.routes.instance_variable_get(:@router)
       .recognize(ActionDispatch::Request.new(Rack::MockRequest.env_for(path, {:method => method}))) do |rt|
         return SensibleRoute.new(rt)
       end
end

# rubocop:disable Metrics/ParameterLists
def log_timestamps(ts, status:, action:, controller:, format:, method:, # rubocop:disable Lint/UnusedMethodArgument
                   view_runtime:, db_runtime:, path:, uuid:) # rubocop:disable Lint/UnusedMethodArgument
  # rubocop:enable Metrics/ParameterLists
  redis_logger = redis(logger: true)
  view_runtime = view_runtime.to_f
  db_runtime = db_runtime.to_f

  return if path.nil?
  path = sensible_routes_wrap(method, path)&.path || path.split('?').first
  path_string = "#{method.upcase}/#{path}.#{format}"
  # controller_action_string = "#{controller}##{action}"
  redis_logger.sadd 'request_timings/path_strings', path_string
  # redis_logger.sadd "request_timings/controller_action_strings", controller_action_string
  redis_logger.zadd "request_timings/view/by_path/#{path_string}", ts, view_runtime
  redis_logger.zadd "request_timings/db/by_path/#{path_string}", ts, db_runtime
  redis_logger.zadd "request_timings/total/by_path/#{path_string}", ts, (db_runtime + view_runtime)
  redis_logger.zremrangebyscore "request_timings/view/by_path/#{path_string}", '-inf', ts - REDIS_LOG_EXPIRATION
  redis_logger.zremrangebyscore "request_timings/db/by_path/#{path_string}", '-inf', ts - REDIS_LOG_EXPIRATION
  redis_logger.zremrangebyscore "request_timings/total/by_path/#{path_string}", '-inf', ts - REDIS_LOG_EXPIRATION
  redis_logger.expire "request_timings/view/by_path/#{path_string}", REDIS_LOG_EXPIRATION
  redis_logger.expire "request_timings/db/by_path/#{path_string}", REDIS_LOG_EXPIRATION
  redis_logger.expire "request_timings/total/by_path/#{path_string}", REDIS_LOG_EXPIRATION

  # redis_logger.zadd "request_timings/view/by_action/#{controller_action_string}", ts, view_runtime
  # redis_logger.zadd "request_timings/db/by_action/#{controller_action_string}", ts, db_runtime
  # redis_logger.zadd "request_timings/total/by_action/#{controller_action_string}", ts, (db_runtime + view_runtime)

  # redis_logger.zadd "request_timings/status_counts/by_path/#{path_string}", ts, status
  # redis_logger.zadd "request_timings/status_counts/by_action/#{controller_action_string}", ts, status
  # redis_logger.zadd 'request_timings/status_counts', ts, status

  # redis_logger.zadd "requests/by_path/#{path_string}", ts, uuid
  # redis_logger.zadd "requests/by_action/#{controller_action_string}", ts, uuid

  # redis_logger.zadd 'request_timings/sha', ts, CurrentCommit, nx: true
end

ActiveSupport::Notifications.subscribe 'process_action.action_controller' do |_name, _started, _finished, _unique_id, data|
  redis_logger = redis(logger: true)
  request_id = data[:headers]['action_dispatch.request_id']
  # redis_log_id = data[:headers]['rack.session']['redis_log_id']
  redis_log_key = data[:headers]['redis_logs.log_key']
  request_timestamp = data[:headers]['redis_logs.timestamp']
  unless request_timestamp.nil?
    # RedisLogJob.perform_later(
    #   data.slice(:controller, :action, :format, :method, :status, :view_runtime, :db_runtime),
    #   subspaces: {
    #     response_headers: data[:headers].to_h['action_controller.instance'].response.headers.to_h
    #   },
    #   status: data[:status],
    #   exception: data.slice(:exception, :exception_object),
    #   time: request_timestamp,
    #   uuid: request_id,
    #   completed: true
    # )
    unless data[:status].nil?
      log_timestamps(request_timestamp, **data.slice(
        :action, :controller,
        :view_runtime, :db_runtime,
        :method, :format, :status
      ), path: data[:path] || redis_logger.hget(redis_log_key, 'path'), uuid: request_id)
    end
  end
end

ActiveSupport::Notifications.subscribe 'endpoint_run.grape' do |_name, _started, _finished, _unique_id, data|
  # request_id = data[:env]['action_dispatch.request_id']
  # # redis_log_id = data[:env]['rack.session']['redis_log_id']
  # request_timestamp = data[:env]['redis_logs.timestamp']
  #
  # RedisLogJob.perform_later(
  #   {
  #     # The API doesn't spit out that much, so I'm doing what I can
  #     controller: nil,
  #     action: nil,
  #     format: data[:env]['api.endpoint'].headers['Content-Type'],
  #     method: data[:env]['grape.routing_args'][:route_info].request_method,
  #     status: 'API',
  #     view_runtime: nil,
  #     db_runtime: Time.now.to_f - data[:env]['redis_logs.start_time'].to_f
  #   },
  #   exception: data.slice(:exception, :exception_object),
  #   time: request_timestamp,
  #   uuid: request_id,
  #   completed: true
  # )
end
