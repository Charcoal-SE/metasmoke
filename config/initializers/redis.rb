# frozen_string_literal: true

require 'redis'

def redis
  $redis ||= Redis.new(AppConfig['redis']) # rubocop:disable Style/GlobalVars
end

def with_no_score(ary)
  zeros = Array.new(ary.length) { 0 }
  elements = ary.map { |i| "\"#{i}\"" }
  zeros.zip(elements) # .flatten
end
