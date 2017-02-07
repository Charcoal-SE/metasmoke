class ApiChannel < ApplicationCable::Channel
  def subscribed
    @key = ApiKey.find_by_key(params[:key])
    if params[:key].present? && @key.present?
      stream_from "api_feedback"
    else
      reject
    end
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
