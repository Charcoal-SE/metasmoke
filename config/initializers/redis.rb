# frozen_string_literal: true

require 'redis'
require 'active_record'

# In theory, I should PR the authors of redis-rb with this, but I'm lazy.
class Redis::Client
  protected

  def logging(commands)
    return yield unless @logger && @logger.debug?

    begin
      commands.each do |name, *args|
        logged_args = args.map do |a|
          if a.respond_to?(:inspect) then a.inspect
          elsif a.respond_to?(:to_s) then a.to_s
          else
            # handle poorly-behaved descendants of BasicObject
            klass = a.instance_exec { (class << self; self end).superclass }
            "\#<#{klass}:#{a.__id__}>"
          end
        end
        @logger.debug("[Redis] command=#{name.to_s.upcase} args=#{logged_args.join(' ')}")
      end

      t1 = Time.now
      yield
    ensure
      if t1
        call_time = (Time.now - t1) * 1000
        ActiveRecord::RuntimeRegistry.sql_runtime = ActiveRecord::RuntimeRegistry.sql_runtime.to_i + call_time
        @logger.debug('[Redis] call_time=%0.2f ms' % call_time) # rubocop:disable Style/FormatString
      end
    end
  end
end

class Redis
  # Yes, I know that monkey patching is bad, but redis is being bad too
  def hgetall(key)
    synchronize do |client|
      client.call([:hgetall, key], &proc { |r| Hashify.call(r.to_a) })
    end
  end
end

def redis(logger: false, new: false)
  if logger
    config = AppConfig['redis_logging']
    return Redis.new(config) if new
    $redis_logging ||= Redis.new(config) # rubocop:disable Style/GlobalVars
  else
    config = YAML.load_file(File.join(Rails.root, 'config', 'cable.yml'))[Rails.env]
    return Redis.new(config) if new
    $redis ||= Redis.new(config) # rubocop:disable Style/GlobalVars
  end
end

redis
redis(logger: true)

def with_no_score(ary)
  zeros = Array.new(ary.length) { 0 }
  elements = ary.map { |i| "\"#{i}\"" }
  zeros.zip(elements) # .flatten
end
