# frozen_string_literal: true

# Be sure to restart your server when you modify this file. Action Cable runs in a loop that does not support auto reloading.
class PostsChannel < ApplicationCable::Channel
  def subscribed
    if params[:post_id].present?
      stream_from "posts_#{params[:post_id]}"
    else
      stream_from 'posts_realtime'
    end
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
