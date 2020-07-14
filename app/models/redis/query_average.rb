# frozen_string_literal: true

class Redis::QueryAverage
  def initialize(method, path)
    @method = method
    @path = path
  end

  def counter(t)
    redis(logger: true).zcard(redis_key(t)).to_i
  end

  def average(t)
    redis(logger: true).zrange(redis_key(t), 0, -1).map(&:to_f).sum / counter(t)
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
