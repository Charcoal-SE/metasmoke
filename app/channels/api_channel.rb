# frozen_string_literal: true

# If you change this to APIChannel, FIRE and AIM will break!
class ApiChannel < ApplicationCable::Channel
  def subscribed
    @key = APIKey.find_by(key: params[:key])
    if params[:key].present? && @key.present?
      if params[:events].present?
        params[:events].split(';').each do |e|
          if e.include? '#'
            event_types = e.split('#')[1].split(',')
            e = e.split('#')[0]
          else
            event_types = %w[create update]
          end
          event_types.each do |et|
            stream_for "#{e}_#{et}"
          end
        end
      else
        stream_from 'api_feedback'
        stream_from 'api_flag_logs'
        stream_from 'api_deletion_logs'
        stream_from 'api_statistics'
        stream_from 'api_github_events'
      end
    else
      reject
    end
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
