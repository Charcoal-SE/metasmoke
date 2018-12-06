require 'redis'

def redis
  @redis ||= Redis.new
end

def with_no_score(ary)
  ary.zip(ary.length.times.map { 0 }).flatten
end
