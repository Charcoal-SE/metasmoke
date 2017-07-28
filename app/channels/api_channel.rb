# frozen_string_literal: true

# If you change this to APIChannel, FIRE and AIM will break!
class ApiChannel < ApplicationCable::Channel
  def subscribed
    @key = APIKey.find_by(key: params[:key])
    if params[:key].present? && @key.present?
      if params[:events].present?
        params[:events].split(';').each do |e|
          stream_from "api_#{e}"
        end
      end
    else
      reject
    end
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
