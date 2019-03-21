# frozen_string_literal: true

class StackExchangeUser < ApplicationRecord
  include Websocket

  belongs_to :site
  has_many :posts
  has_many :feedbacks, through: :posts

  # Note: the user_id field on this model refers to the SE user id, not
  #       a user in the users table on MS

  def stack_link
    "#{site.site_url}/users/#{user_id}"
  end

  def flair_link
    "#{site.site_url}/users/flair/#{user_id}.png"
  end

  def self.populate_all_redis
    redis.pipelined do
      includes(:posts).find_each(batch_size: 6000) { |u| Redis::StackExchangeUser.populate(u) }
    end
  end

  def blacklist_for_post(post)
    ActionCable.server.broadcast 'smokedetector_messages', blacklist: {
      uid: user_id.to_s,
      site: URI.parse(site.site_url).host,
      post: post.link
    }
  end

  def unblacklist_user
    ActionCable.server.broadcast 'smokedetector_messages', unblacklist: {
      uid: user_id.to_s,
      site: URI.parse(site.site_url).host
    }
  end
end
