# frozen_string_literal: true

class Redis::SiteSetting
  PREFIX = 'site_setting'

  def self.bool(name)
    redis.get("#{PREFIX}/#{name}").nil? ? false : true
  end

  def self.get(name)
    redis.get "#{PREFIX}/#{name}"
  end

  def self.set(name, val)
    v = 1 if val == true
    v = nil if val == false
    redis.set "#{PREFIX}/#{name}", v
  end
end
