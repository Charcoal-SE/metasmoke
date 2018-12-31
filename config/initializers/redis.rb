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
          case
          when a.respond_to?(:inspect) then a.inspect
          when a.respond_to?(:to_s)    then a.to_s
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
        @logger.debug("[Redis] call_time=%0.2f ms" % (call_time))
      end
    end
  end
end

def redis
  $redis ||= Redis.new(AppConfig['redis'].merge(logger: Logger.new(File.join(Rails.root, 'log', 'redis.log'))))
end

def with_no_score(ary)
  zeros = Array.new(ary.length) { 0 }
  elements = ary.map { |i| "\"#{i}\"" }
  zeros.zip(elements) # .flatten
end
