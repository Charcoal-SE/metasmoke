class Redis::Base::Set
  def initialize(id)
    @source_id = id
  end

  def intersect(target_key, **opts)
    target_key.to_key if target_key.is_a? Redis::Base::Set
    Redis::Base::Collection.intersect(key, target_key, **opts)
  end

  def method_missing(m, *args, &block)
    return target_all(*args, &block) if m == target
    super(m, *args, &block)
  end

  def respond_to_missing?(m, include_private = false)
    m == target
  end

  def to_key
    key
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

  def id
    @source_id
  end

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
      @prefix ||= self.to_s.downcase.to_sym
    end

    def target
      throw "No target defined for #{self}" unless @target
      @target
    end
  end
end
