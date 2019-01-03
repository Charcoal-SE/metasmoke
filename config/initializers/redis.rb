# frozen_string_literal: true

require 'redis'

def redis
  config = YAML.load_file(File.join(Rails.root, 'config', 'cable.yml'))[Rails.env]
  $redis ||= Redis.new(config) # rubocop:disable Style/GlobalVars
end

redis

def with_no_score(ary)
  zeros = Array.new(ary.length) { 0 }
  elements = ary.map { |i| "\"#{i}\"" }
  zeros.zip(elements) # .flatten
end
