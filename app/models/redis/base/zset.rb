class Redis::Base::ZSet
  def all(id)
    id.to_i
    redis.zrange "#{prefix}/#{id}", 0, -1
  end

  private

  def prefix=(nprefix)
    @prefix = nprefix
  end

  def prefix
    @prefix ||= self.class.to_s.downcase
  end
end
