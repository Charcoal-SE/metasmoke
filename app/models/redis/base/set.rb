# frozen_string_literal: true

class Redis::Base::Set
  def id
    @source_id
  end

  def initialize(id)
    @source_id = id
  end

  def intersect(*target_keys, **opts)
    target_keys.map! { |tk| tk.is_a?(Redis::Base::Set) ? tk.to_key : tk }
    Redis::Base::Collection.intersect(key, target_keys, **opts)
  end

  def difference(*target_keys, **opts)
    target_keys.map! { |tk| tk.is_a?(Redis::Base::Set) ? tk.to_key : tk }
    Redis::Base::Collection.difference(key, target_keys, **opts)
  end

  def method_missing(m, *args, &block)
    return target_all(*args, &block) if m == target
    super
  end

  def respond_to_missing?(m, _include_private = false)
    m == target
  end

  def to_key
    key
  end

  def count
    redis.scard key
  end

  private

  def target_all
    redis.smembers "#{prefix}/#{id}"
  end

  def key
    @key ||= "#{prefix}/#{id}"
  end

  def target
    self.class.target
  end

  # def id
  #   @source_id
  # end

  def prefix
    self.class.prefix
  end

  class << self
    def find(id)
      new(id.to_i)
    end

    def source_type(nprefix)
      @prefix = nprefix.to_sym
    end

    def target_name(ntarget)
      @target = ntarget.to_sym
    end

    def prefix
      @prefix ||= to_s.downcase.to_sym
    end

    def target
      throw "No target defined for #{self}" unless @target
      @target
    end
  end
end
