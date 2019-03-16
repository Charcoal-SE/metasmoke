# frozen_string_literal: true

class Redis::QueryAverage
  def initialize(method, path)
    @method = method
    @path = path
    @redis_key = "request_timings/db/by_path/#{@method}/#{@path}"
  end

  def counter
    redis(logger: true).zcard(@redis_key).to_i
  end

  def average
    redis(logger: true).zrange(@redis_key, 0, -1).map(&:to_f).sum / counter
  end

  def path
    "#{@method} #{@path}"
  end
end
