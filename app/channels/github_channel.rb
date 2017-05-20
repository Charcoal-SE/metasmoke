# frozen_string_literal: true

# Be sure to restart your server when you modify this file. Action Cable runs in a loop that does not support auto reloading.
class GithubChannel < ApplicationCable::Channel
  def subscribed
    stream_from 'github_new_commit'
  end
end
