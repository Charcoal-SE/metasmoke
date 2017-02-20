class FlagLogsChannel < ApplicationCable::Channel
  def subscribed
    stream_from "flag_logs"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
