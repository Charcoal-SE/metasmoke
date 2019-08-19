# frozen_string_literal: true

class RedisLogChannel < ApplicationCable::Channel
  def subscribed
    if !current_user.nil? && current_user.has_role?(:developer)
      %i[status path session].each do |filter|
        if params[filter].present?
          stream_from "redis_log_#{filter}_#{params[filter]}"
          return # rubocop:disable Lint/NonLocalExitFromIterator
        end
      end
      stream_from 'redis_log_channel'
    else
      reject
    end
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end

  def new; end
end
