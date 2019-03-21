# frozen_string_literal: true

class Redis::StackExchangeUser
  attr_reader :fields, :id, :post_ids

  def initialize(id, **overrides)
    @id = id
    @fields = redis.hgetall("stack_exchange_user/#{id}").merge(overrides)
    @post_ids = redis.smembers("stack_exchange_user/#{id}/posts")
  end

  %w[username site_id user_id reputation].each do |m|
    define_method(m) { @fields[m] }
  end

  def site
    @site ||= Site.find(site_id)
  end

  def stack_link
    "#{site.site_url}/users/#{user_id}"
  end

  def flair_link
    "#{site.site_url}/users/flair/#{user_id}.png"
  end

  def posts
    @posts ||= @post_ids.map { |id| Redis::Post.new(id) }
  end

  def self.populate(user)
    raise "Not a User object" unless user.is_a? StackExchangeUser

    redis.multi do |m|
      m.sadd "stack_exchange_users", user.id
      m.sadd "stack_exchange_user/#{user.id}/posts", user.posts.map(&:id) unless user.posts.empty?
      m.mapped_hmset "stack_exchange_user/#{user.id}", user.attributes.except("id")
    end
  end
end
