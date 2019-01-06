# frozen_string_literal: true

class Redis::Post
  attr_reader :fields, :id

  def initialize(id, **overrides)
    @id = id
    @fields = redis.hgetall("posts/#{id}").merge(overrides)
  end

  def all(type:)
    case type
    when :set
      Redis::Base::Collection.new('all_posts', type: type)
    when :zset
      Redis::Base::Collection.new('posts', type: type)
    end
  end

  %w[body title link username why stack_exchange_user_id site_id].each do |field|
    define_method(field) { @fields[field] }
  end

  def created_at
    @created_at ||= @fields['created_at'].to_s.to_time
  end

  def stack_exchange_user
    @stack_exchange_user ||= Redis::StackExchangeUser.new(
      @fields['stack_exchange_user_id'],
      username: @fields['stack_exchange_user_username']
    )
  end

  def cachebreak
    Rack::MiniProfiler.step("Generating cachebreaker for Post##{id}") do
      "#{id}:#{feedbacks.map(&:id).join(',')}:#{comments.count}"
    end
  end

  def comments
    if @comments.nil?
      @comments = Array.new(@fields['post_comments_count'].to_i) { Redis::PostComment.new(nil) }
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
