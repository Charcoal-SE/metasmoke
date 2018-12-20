# frozen_string_literal: true

require 'redis'

def redis
  $redis ||= Redis.new(timeout: 0, port: 1234)
end

def with_no_score(ary)
  zeros = Array.new(ary.length) { 0 }
  elements = ary.map { |i| "\"#{i}\"" }
  zeros.zip(elements) # .flatten
end
