# frozen_string_literal: true

class Redis::Base::ZSet
  def all(id)
    id.to_i
    redis.zrange "#{prefix}/#{id}", 0, -1
  end

  private

  attr_writer :prefix

  def prefix
    @prefix ||= self.class.to_s.downcase
  end
end
