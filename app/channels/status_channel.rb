# frozen_string_literal: true

class StatusChannel < ApplicationCable::Channel
  def subscribed
    stream_from 'status'
  end
end
