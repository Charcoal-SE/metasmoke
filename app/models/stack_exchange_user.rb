# frozen_string_literal: true

class StackExchangeUser < ApplicationRecord
  include Websocket

  belongs_to :site
  has_many :posts
  has_many :feedbacks, through: :posts

  def stack_link
    "#{site.site_url}/users/#{user_id}"
  end

  def flair_link
    "#{site.site_url}/users/flair/#{user_id}.png"
  end

  def blacklist_for_post(post)
    ActionCable.server.broadcast 'smokedetector_messages', blacklist: {
      uid: user_id.to_s,
      site: URI.parse(site.site_url).host,
      post: post.link
    }
  end
end
