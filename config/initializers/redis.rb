require 'redis'

def redis
  @redis ||= Redis.new
end

def with_no_score(ary)
  zeros = ary.length.times.map { 0 }
  elements = ary.map { |i| "\"#{i}\""}
  zeros.zip(elements)#.flatten
end
