# frozen_string_literal: true

class RedisLogController < ApplicationController
  before_action :authenticate_user!
  before_action :verify_developer

  def by_user
    redis = redis(logger: true)
    user_id = params[:id]
    si, ei = page
    @sessions = redis.zrevrange("user_sessions/#{user_id}", si, ei).map do |session_id|
      requests = redis.zrange("session/#{session_id}/requests", 0, 20, with_scores: true)
      if redis.zcard("session/#{session_id}/requests") == 0
        redis.multi do
          redis.del "session/#{session_id}/requests"
          redis.del "session/#{session_id}"
        end
        {}
      else
        redis.hgetall("session/#{session_id}").merge(
          id: session_id,
          user_id: user_id,
          count: requests.length,
          requests: requests.map do |request_id, timestamp|
                      r = get_request(timestamp, request_id)
                      redis.zrem "session/#{session_id}/requests", request_id if r.empty?
                      r
                    end.reject(&:empty?)
        )
      end
    end.reject(&:empty?)
    render :user_sessions
  end

  def index
    redis = redis(logger: true)
    si, ei = page
    @requests = redis.zrevrange('requests', si, ei, with_scores: true).map do |request_id, timestamp|
      r = get_request(timestamp, request_id)
      redis.zrem 'requests', request_id if r.empty?
      r
    end.reject(&:empty?)
  end

  def by_session
    redis = redis(logger: true)
    @session_id = params[:id]
    si, ei = page
    @requests = if redis.zcard("session/#{@session_id}/requests") == 0
      redis.multi do
        redis.del "session/#{@session_id}/requests"
        redis.del "session/#{@session_id}"
      end
      {}
    else
      redis.zrange("session/#{@session_id}/requests", si, ei, with_scores: true).map do |request_id, timestamp|
        r = get_request(timestamp, request_id)
        redis.zrem "session/#{@session_id}/requests", request_id if r.empty?
        r
      end.reject(&:empty?)
    end
  end

  def by_status
    redis = redis(logger: true)
    @status = params[:status]
    si, ei = page
    @requests = redis.zrevrange("requests/status/#{@status}", si, ei, with_scores: true).map do |request_id, timestamp|
      r = get_request(timestamp, request_id)
      redis.zrem "requests/status/#{@status}", request_id if r.empty?
      r
    end.reject(&:empty?)
  end

  private

  def get_request(timestamp, request_id)
    redis = redis(logger: true)
    from_redis = redis.hgetall("request/#{timestamp}/#{request_id}")
    return {} if from_redis.empty?
    from_redis.merge(
      request_headers: redis.hgetall("request/#{timestamp}/#{request_id}/request_headers"),
      response_headers: redis.hgetall("request/#{timestamp}/#{request_id}/response_headers"),
      params: redis.hgetall("request/#{timestamp}/#{request_id}/params"),
      exception: redis.hgetall("request/#{timestamp}/#{request_id}/exception"),
      timestamp: timestamp,
      request_id: request_id,
      key: "#{timestamp.to_s.tr('.', '-')}-#{request_id}"
    )
  end

  def page
    pagesize = params[:pagesize].present? ? params[:pagesize].to_i : 50
    start_idx = (((params[:page].present? ? params[:page].to_i : 1) - 1) * pagesize)
    end_idx = start_idx + pagesize
    [start_idx, end_idx]
  end
end
