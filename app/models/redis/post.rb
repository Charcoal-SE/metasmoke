# frozen_string_literal: true

class Redis::Post
  attr_reader :fields, :id

  FIELD_LIST = %i[body title link username why stack_exchange_user_id site_id created_at].freeze
  attr_reader(*FIELD_LIST)

  def initialize(id, **overrides)
    @id = id
    @fields = fetch_redis_fields.merge(overrides)
    FIELD_LIST.each do |field|
      instance_variable_set("@#{field}", @fields[field.to_s] || @fields[field])
    end
    @created_at = @created_at&.to_time
  end

  def fetch_redis_fields
    fields = redis.hgetall("posts/#{@id}")
    return fields unless fields.empty?
    self.class.to_redis(Post.find(@id))
  end

  private :fetch_redis_fields
  def self.to_redis(post)
    post_hsh = {
      'body' => post.body,
      'title' => post.title,
      'reason_weight' => post.reasons.map(&:weight).reduce(:+),
      'created_at' => post.created_at,
      'username' => post.username,
      'link' => post.link,
      'site_site_logo' => post.site.try(:site_logo),
      'stack_exchange_user_username' => post.stack_exchange_user.try(:username),
      'stack_exchange_user_id' => post.stack_exchange_user.try(:id),
      'flagged' => post.flagged?,
      'site_id' => post.site_id,
      'post_comments_count' => post.comments.count,
      'why' => post.why
    }
    redis.hmset("posts/#{post.id}", *post_hsh.to_a)
    redis.expire("posts/#{post.id}", 1.hour)
    post_hsh
  end

  def self.all(type:)
    case type
    when :set
      Redis::Base::Collection.new('all_posts', type: type)
    when :zset
      Redis::Base::Collection.new('posts', type: type)
    end
  end

  def stack_exchange_user
    @stack_exchange_user ||= Redis::StackExchangeUser.new(
      @stack_exchange_user_id,
      username: @fields['stack_exchange_user_username'],
      still_alive: @fields['stack_exchange_user_still_alive']
    )
  end

  def cachebreak
    Rack::MiniProfiler.step("Generating cachebreaker for Post##{id}") do
      "#{id}:#{feedbacks.map(&:id).join(',')}:#{comments.count}"
    end
  end

  def comments
    if @comments.nil?
      comments_count = @fields['post_comments_count']
      if comments_count.to_i < 0
        debug_prefix = "[Redis::Post comments] SE ID: #{@fields['site_id']}:"
        Rails.logger.debug "#{debug_prefix} post_comments_count (#{comments_count.to_i}) < 0: #{comments_count}"
      end
      @comments = Array.new([@fields['post_comments_count'].to_i, 0].max) { Redis::PostComment.new(nil) }
      @comments.define_singleton_method(:count) { length }
    end
    @comments
  end

  def site
    @site ||= if !@fields['site_site_logo'].nil? && !@fields['site_id'].nil?
                Site.new(site_logo: @fields['site_site_logo'], id: @fields['site_id'])
              end
  end

  def flagged?
    @flagged ||= rpost['flagged'] == 'true'
  end

  def reasons
    if @reasons.nil?
      reason_names = redis.zrange "posts/#{id}/reasons", 0, -1, with_scores: true
      @reasons = reason_names.map do |rn, weight|
        Reason.new(reason_name: rn, weight: weight)
      end
    end
    @reasons
  end

  def feedbacks
    @feedbacks ||= Redis::Feedback.post(id)
  end

  def deletion_logs
    @deletion_logs ||= DeletionLog.from_redis(id)
  end

  def deleted_at
    @deleted_at ||= deletion_logs.empty? ? nil : deletion_logs.first.created_at
  end
end
