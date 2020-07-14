# frozen_string_literal: true

class Redis::QueryAverage
  def initialize(method, path, since: 0)
    @since = since
    @method = method
    @path = path
  end

  def counter(t)
    redis(logger: true).zcount(redis_key(t), @since, '+inf').to_i
  end

  def average(t)
    count = counter(t)
    return Float::INFINITY if count == 0
    redis(logger: true).zrangebyscore(redis_key(t), @since, '+inf').map(&:to_f).sum / count
  end

  def path
    "#{@method} #{@path}"
  end

  def raw_path
    "#{@method}/#{@path}"
  end

  def reset
    %i[db total view].each do |t|
      redis(logger: true).del(redis_key(t))
    end
    redis(logger: true).srem 'request_timings/path_strings', raw_path
  end

  def redis_key(t)
    "request_timings/#{t}/by_path/#{@method}/#{@path}"
  end
end
