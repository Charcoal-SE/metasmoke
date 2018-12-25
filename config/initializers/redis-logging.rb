ActiveSupport::Notifications.subscribe "process_action.action_controller" do |name, started, finished, unique_id, data|
  request_id = data[:headers]["action_dispatch.request_id"]
  redis_log_id = data[:headers]["rack.session"]["redis_log_id"]
  redis_log_key = data[:headers]["redis_logs.log_key"]
  request_timestamp = data[:headers]["redis_logs.timestamp"]
  redis.zadd "requests/status/#{data[:status]}", request_timestamp, request_id
  redis.mapped_hmset redis_log_key, data.slice(:controller, :action, :format, :method, :status, :view_runtime, :db_runtime)
  if data[:exception].present?
    redis.hset redis_log_key, "exception", data[:exception].join("\n")
    ex = data[:exception_object]
    redis.mapped_hmset "#{redis_log_key}/exception", {
      file_name: ex.try(:file_name),
      annotated_source_code: ex.try(:annoted_source_code)&.join("\n"),
      line_number: ex.try(:line_number),
      backtrace: ex.try(:backtrace)&.join("\n"),
      message: ex.try(:message)
    }
  end
  RedisLogJob.perform_later(request_id, request_timestamp)
end
