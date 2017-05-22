# frozen_string_literal: true

# Be sure to restart your server when you modify this file. Action Cable runs in a loop that does not support auto reloading.
class SmokeDetectorChannel < ApplicationCable::Channel
  def subscribed
    if SmokeDetector.find_by_access_token(params[:key]).present?
      stream_from 'smokedetector_messages'
    else
      reject
    end
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
