class Redis::SiteSetting
  PREFIX = "site_setting"

  class << self
    def bool(name)
      redis.get("#{PREFIX}/#{name}").nil? ? false : true
    end

    def get(name)
      redis.get "#{PREFIX}/#{name}"
    end

    def set(name, val)
      v = 1 if val == true
      v = nil if val == false
      redis.set "#{PREFIX}/#{name}", v
    end
  end
end
