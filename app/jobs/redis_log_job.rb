# frozen_string_literal: true

require 'yaml'

class RedisLogJob < ApplicationJob
  queue_as :default
  before_enqueue do |job|
    job.arguments.map!(&:to_yaml)
  end

  before_perform do |job|
    job.arguments.map! { |arg| YAML.load(arg) } # rubocop:disable Security/YAMLLoad
  end

  # rubocop:disable Metrics/ParameterLists
  def perform(root, subspaces: {}, status: nil, exception: {}, session_id: nil, user_id: nil, time:, uuid:, completed: false)
    # rubocop:enable Metrics/ParameterLists
    keyspace_map = subspaces
    @time = time
    @uuid = uuid
    @redis = redis(logger: true, new: true)
    # Because ActionJob is async, sometimes the second set of info will come before data from the first is in redis. That causes bad.
    if completed
      @redis.set("#{redis_log_key}/metastatus", Time.now.to_i, nx: true)
      if @redis.get("#{redis_log_key}/metastatus") != 'before_action' && Time.now.to_i - @redis.get("#{redis_log_key}/metastatus").to_i < 20
        retry_job wait: (1 / 2).seconds
        return
      else
        @redis.del "#{redis_log_key}/metastatus"
      end
    end
    @redis.multi
    @redis.mapped_hmset redis_log_key, root
    @redis.expire redis_log_key, REDIS_LOG_EXPIRATION
    log_to_namespace(redis_log_key, keyspace_map)
    log_exception(exception) if exception[:exception].present?
    @redis.zadd "requests/status/#{status}", @time, @uuid unless status.nil?
    unless completed
      # These things only need to be done once
      log_session(session_id, user_id)
      @redis.zadd 'requests', @time, @uuid
    end
    @redis.set "#{redis_log_key}/metastatus", 'before_action' unless completed
    @redis.exec

    send_out_websocket(completed)
  end

  private

  def redis_log_key
    # We include the time just to doubly ensure that the uuid is unique
    "request/#{@time}/#{@uuid}"
  end

  def log_to_namespace(namespace, keyspaces)
    keyspaces.each do |subspace, hsh|
      next if hsh.empty?
      @redis.mapped_hmset "#{namespace}/#{subspace}", hsh
      @redis.expire "#{namespace}/#{subspace}", REDIS_LOG_EXPIRATION
    end
  end

  def log_session(session_id, user_id)
    return if session_id.nil?
    # TODO: If we care more about memory than speed, switch session/*/requests and user_sessions/* to be sets and
    # intersect them with requests to get a zset when you need one.
    @redis.zadd "session/#{session_id}/requests", @time, @uuid
    @redis.expire "session/#{session_id}/requests", REDIS_LOG_EXPIRATION
    @redis.hsetnx("session/#{session_id}", 'start', @time)
    @redis.hset("session/#{session_id}", 'end', @time)
    @redis.expire "session/#{session_id}", REDIS_LOG_EXPIRATION
    return unless user_id.nil?
    @redis.zadd "user_sessions/#{user_id}", @time, session_id
    @redis.expire "user_sessions/#{user_id}", REDIS_LOG_EXPIRATION * 3
  end

  def log_exception(data)
    @redis.hset redis_log_key, 'exception', data[:exception].join("\n")
    ex = data[:exception_object]
    @redis.mapped_hmset "#{redis_log_key}/exception", file_name: ex.try(:file_name),
                                                      annotated_source_code: ex.try(:annoted_source_code)&.join("\n"),
                                                      line_number: ex.try(:line_number),
                                                      backtrace: ex.try(:backtrace)&.join("\n"),
                                                      message: ex.try(:message)
    @redis.expire "#{redis_log_key}/exception", REDIS_LOG_EXPIRATION
  end

  def send_out_websocket(completed)
    info = @redis.hgetall(redis_log_key)
                 .merge(request_headers: @redis.hgetall("#{redis_log_key}/request_headers"),
                        response_headers: @redis.hgetall("#{redis_log_key}/response_headers"),
                        params: @redis.hgetall("#{redis_log_key}/params"),
                        exception: @redis.hgetall("#{redis_log_key}/exception"),
                        timestamp: @time,
                        request_id: @uuid,
                        logs: @redis.lrange("#{redis_log_key}/logs", 0, -1),
                        key: "#{@time.to_s.tr('.', '-')}-#{@uuid}")
    ActionCable.server.broadcast 'redis_log_channel',
                                 key: "#{@time.to_s.tr('.', '-')}-#{@uuid}",
                                 precedence: completed ? 1 : 0,
                                 html: ApplicationController.render(
                                   template: 'redis_log/_row',
                                   locals: { req: info, wrapped: true },
                                   layout: nil
                                 )
  end
end
