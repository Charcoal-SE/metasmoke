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
      redis.hgetall("session/#{session_id}").merge(
        id: session_id,
        user_id: user_id,
        count: requests.length,
        requests: requests.map do |request_id, timestamp|
                    redis.hgetall("request/#{timestamp}/#{request_id}").merge(
                      headers: redis.hgetall("request/#{timestamp}/#{request_id}/headers"),
                      params: redis.hgetall("request/#{timestamp}/#{request_id}/params"),
                      exception: redis.hgetall("request/#{timestamp}/#{request_id}/exception"),
                      timestamp: timestamp,
                      request_id: request_id,
                      key: "#{timestamp.to_s.tr('.', '-')}-#{request_id}"
                    )
                  end
      )
    end
    render :user_sessions
  end

  def index
    redis = redis(logger: true)
    si, ei = page
    @requests = redis.zrevrange('requests', si, ei, with_scores: true).map do |request_id, timestamp|
      redis.hgetall("request/#{timestamp}/#{request_id}").merge(
        request_headers: redis.hgetall("request/#{timestamp}/#{request_id}/request_headers"),
        response_headers: redis.hgetall("request/#{timestamp}/#{request_id}/response_headers"),
        params: redis.hgetall("request/#{timestamp}/#{request_id}/params"),
        exception: redis.hgetall("request/#{timestamp}/#{request_id}/exception"),
        timestamp: timestamp,
        request_id: request_id,
        key: "#{timestamp.to_s.tr('.', '-')}-#{request_id}"
      )
    end
  end

  def by_session
    redis = redis(logger: true)
    @session_id = params[:id]
    si, ei = page
    @requests = redis.zrange("session/#{@session_id}/requests", si, ei, with_scores: true).map do |request_id, timestamp|
      redis.hgetall("request/#{timestamp}/#{request_id}").merge(
        request_headers: redis.hgetall("request/#{timestamp}/#{request_id}/request_headers"),
        response_headers: redis.hgetall("request/#{timestamp}/#{request_id}/response_headers"),
        params: redis.hgetall("request/#{timestamp}/#{request_id}/params"),
        exception: redis.hgetall("request/#{timestamp}/#{request_id}/exception"),
        timestamp: timestamp,
        request_id: request_id,
        key: "#{timestamp.to_s.tr('.', '-')}-#{request_id}"
      )
    end
  end

  def by_status
    redis = redis(logger: true)
    @status = params[:status]
    si, ei = page
    @requests = redis.zrevrange("requests/status/#{@status}", si, ei, with_scores: true).map do |request_id, timestamp|
      redis.hgetall("request/#{timestamp}/#{request_id}").merge(
        request_headers: redis.hgetall("request/#{timestamp}/#{request_id}/request_headers"),
        response_headers: redis.hgetall("request/#{timestamp}/#{request_id}/response_headers"),
        params: redis.hgetall("request/#{timestamp}/#{request_id}/params"),
        exception: redis.hgetall("request/#{timestamp}/#{request_id}/exception"),
        timestamp: timestamp,
        request_id: request_id,
        key: "#{timestamp.to_s.tr('.', '-')}-#{request_id}"
      )
    end
  end

  private

  def page
    pagesize = params[:pagesize].present? ? params[:pagesize].to_i : 50
    start_idx = (((params[:page].present? ? params[:page].to_i : 1) - 1) * pagesize) + 1
    end_idx = start_idx + pagesize
    [start_idx, end_idx]
  end
end
