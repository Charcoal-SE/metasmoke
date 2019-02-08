# frozen_string_literal: true

class Redis::Base::Collection
  attr_reader :key, :intersects

  def initialize(key, type: :set, intersects: [], differences: [])
    @type = type
    @key = key.to_s
    @intersects = intersects
    @differences = differences
  end

  def update!
    store(@key)
  end

  def intersect(*target_keys, type: @type)
    target_keys.map! { |tk| tk.respond_to?(:to_key) ? tk.to_key : tk }
    type = type.to_sym
    throw "Invalid type #{type}" unless %i[set zset].include? type
    Redis::Base::Collection.new(@key, type: type, intersects: @intersects.dup.push(target_keys).flatten, differences: @differences)
  end

  def difference(*target_keys, type: @type)
    target_keys.map! { |tk| tk.respond_to?(:to_key) ? tk.to_key : tk }
    type = type.to_sym
    throw "Invalid type #{type}" unless %i[set zset].include? type
    Redis::Base::Collection.new(@key, type: type, intersects: @intersects, differences: @differences.dup.push(target_keys).flatten)
  end

  def paginate(pagenum, pagesize, &mod)
    pagenum = [pagenum.to_i - 1, 0].max
    res = evaluate([pagenum * pagesize, (pagenum + 1) * pagesize]).map(&mod)
    res.define_singleton_method(:total_pages) { res.length / pagesize }
    res.define_singleton_method(:current_page) { pagenum + 1 }
    res
  end

  def cardinality
    # Eval to tmpkey and then zcard
    if @differences.empty? && @intersects.empty?
      return case @type
             when :set
               redis.scard @key
             when :zset
               redis.zcard @key
             end
    end
    redis.multi do |multi|
      key = "tmp/collection/#{Time.now.to_i}"
      case @type
      when :zset
        multi.zinterstore key, [@key, @intersects].flatten unless @intersects.empty?
        multi.zdiffstore key, key, @differences unless @differences.empty?
        multi.zcard key
      when :set
        multi.sinterstore key, [@key, @intersects].flatten unless @intersects.empty?
        multi.sdiffstore key, key, @differences unless @differences.empty?
        multi.scard key
      end
      multi.del key
    end[2] # This is black magic to me. I'm really unsure what it is.
  end

  def evaluate(bounds = nil, order: nil)
    key = "tmp/collection/#{Time.now.to_i}"
    case @type
    when :set
      puts 'Cannot accept bounds for SET' unless bounds.nil?
      puts 'Cannot ordering for SET' unless order.nil?
      redis.sinterstore key, *@intersects
      redis.sdiff key, @differences
    when :zset
      bounds ||= [0, -1]
      redis.multi do
        redis.zinterstore key, [@key, @intersects].flatten
        redis.zdiffstore key, key, @differences
        if order.to_s.casecmp('ASC') == 0
          redis.zrange key, *bounds
        else
          redis.zrevrange key, *bounds
        end
        redis.del key
      end[2]
    end
  end

  def store(key)
    # TODO: For all the commands in this section, doing this will an empty @intersects or @differences will explode in unknown ways
    throw 'WHUT R U STORIN' if @intersects.empty? && @differences.empty?
    redis.multi do |_multi|
      case @type
      when :set
        redis.sinterstore key, @key, @intersects unless @intersects.empty?
        redis.sdiffstore key, @key, @differences unless @differences.empty?
      when :zset
        redis.zinterstore key, [@key, @intersects].flatten unless @intersects.empty?
        redis.zdiffstore key, key, @differences unless @differences.empty?
      end
    end
  end

  class << self
    def intersect(key1, key2, **opts)
      Redis::Base::Collection.new(key1).intersect(key2, **opts)
    end
  end
end
