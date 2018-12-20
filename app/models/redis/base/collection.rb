# frozen_string_literal: true

class Redis::Base::Collection
  def initialize(key, type: :set)
    @type = type
    @key = key
    @operations = []
  end

  def intersect(nkey, type: @type)
    nkey = nkey.to_key if nkey.respond_to? :to_key
    type = type.to_sym
    throw "Invalid type #{type}" unless %i[set zset].include? type
    counter = redis.incr 'collection/counter'
    fkey = "collections/#{counter}"
    if type == :set
      redis.sinterstore fkey, @key, nkey
    elsif type == :zset
      redis.zinterstore fkey, [@key, nkey]
    end
    Redis::Base::Collection.new(fkey, type: type)
  end

  def paginate(pagenum, pagesize, &mod)
    pagenum = [pagenum.to_i - 1, 0].max
    res = evaluate([pagenum * pagesize, (pagenum + 1) * pagesize]).map(&mod)
    res.define_singleton_method(:total_pages) { res.length / pagesize }
    res.define_singleton_method(:current_page) { pagenum + 1 }
    res
  end

  def cardinality
    case @type
    when :zset
      redis.zcard @key
    when :set
      redis.scard @key
    end
  end

  def evaluate(bounds = nil, order: nil)
    case @type
    when :set
      puts 'Cannot accept bounds for SET' unless bounds.nil?
      puts 'Cannot ordering for SET' unless order.nil?
      redis.smembers @key
    when :zset
      bounds ||= [0, -1]
      if order.to_s.casecmp('ASC') == 0
        redis.zrange @key, *bounds
      else
        redis.zrevrange @key, *bounds
      end
    end
  end

  class << self
    def intersect(key1, key2, **opts)
      Redis::Base::Collection.new(key1).intersect(key2, **opts)
    end
  end
end
