class Redis::Post
  attr_reader :fields

  def initialize(id, **overrides)
    @id = id
    @fields = redis.hgetall("posts/#{id}").merge(overrides)
  end

  %w[body title link username why stack_exchange_user_id site_id].each do |field|
    define_method(field) { @fields[field] }
  end

  def id
    @id
  end

  def created_at
    @created_at ||= @fields["created_at"].to_time
  end

  def stack_exchange_user
    @stack_exchange_user ||= StackExchangeUser.new(
      username: @fields['stack_exchange_user_username'],
      id: @fields['stack_exchange_user_id'].to_i
    )
  end

  def cachebreak
    cb = feedbacks.map(&:id).push(comments.count).join(",")
    puts cb
    cb
  end

  def comments
    if @comments.nil?
      @comments = Array.new(@fields['post_comments_count'].to_i) { PostComment.new }
      c = @fields['post_comments_count'].to_i
      @comments.define_singleton_method(:count) { c }
    end
    @comments
  end

  def site
    @site ||= Site.new(site_logo: @fields['site_site_logo'], id: @fields['site_id'])
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
    @feedbacks ||= Feedback.from_redis(id)
  end

  def deletion_logs
    @deletion_logs ||= DeletionLog.from_redis(id)
  end

  def deleted_at
    @deleted_at ||= deletion_logs.first.created_at unless deletion_logs.empty?
  end
end
