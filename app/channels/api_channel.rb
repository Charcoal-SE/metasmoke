# frozen_string_literal: true

class APIChannel < ApplicationCable::Channel
  def subscribed
    @key = APIKey.find_by(key: params[:key])
    if params[:key].present? && @key.present?
      stream_from 'api_feedback'
      stream_from 'api_flag_logs'
      stream_from 'api_deletion_logs'
      stream_from 'api_statistics'
    else
      reject
    end
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
