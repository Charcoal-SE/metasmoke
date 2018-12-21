# frozen_string_literal: true

class Redis::Feedback
  attr_reader :fields, :id

  def initialize(id, **overrides)
    @id = id
    @fields = redis.hgetall("feedbacks/#{id}").merge(overrides)
  end

  %w[feedback_type user_name is_invalidated].each do |m|
    define_method(m) { @fields[m] }
  end

  def api_key
    @api_key ||= APIKey.new(app_name: @fields['app_name'])
  end

  def user
    @user ||= User.new(username: user_name)
  end

  def self.post(post_id)
    feedback_ids = redis.zrange "post/#{post_id}/feedbacks", 0, -1
    feedback_ids.map { |id| Redis::Feedback.new(id) }
  end

  # Stolen from feedbacks model

  def is_positive? # rubocop:disable Style/PredicateName
    feedback_type.include? 't'
  end

  def is_negative? # rubocop:disable Style/PredicateName
    feedback_type.include? 'f'
  end

  def is_naa? # rubocop:disable Style/PredicateName
    feedback_type.include? 'naa'
  end
end
