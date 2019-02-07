# frozen_string_literal: true

class RedisLogChannel < ApplicationCable::Channel
  def subscribed
    # binding.irb
    stream_from 'redis_log_channel' if !current_user.nil? && current_user.has_role?(:developer)
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end

  def new; end
end
