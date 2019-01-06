class Redis::CI
  PREFIX = "ci"
  CI_COUNTER_PREFIX = "sucessful_ci_count"

  def initialize(sha)
    @sha = sha
  end

  def sucess_count_incr(sha)
    key = "#{PREFIX}/#{CI_COUNTER_PREFIX}/#{sha}"
    redis.multi
      redis.incr key
      redis.expire key, 1200
    end[0]
  end

  def sucess_count_reset(sha)
    redis.del "#{PREFIX}/#{CI_COUNTER_PREFIX}/#{sha}"
  end

  def sucess_count(sha)
    redis.get("#{PREFIX}/#{CI_COUNTER_PREFIX}/#{sha}").to_i
  end

  private

  attr_accessor :sha
end
