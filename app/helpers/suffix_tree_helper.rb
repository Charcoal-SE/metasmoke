# frozen_string_literal: true

require 'singleton'

module SuffixTreeHelper
  class SuffixTreeSingleton < SuffixTree
    include Singleton
    def initialize
      super AppConfig['suffix_tree']['path']
      @functional = true
      @reason = ''
    end

    def mark_functional
      @functional = true
    end

    def mark_broken(reason)
      @functional = false
      @reason = reason
    end

    def functional?
      @functional
    end

    def broken_reason
      @reason
    end
  end

  Field_bitmask = {
    :title => 1,
    :body => 2,
    :why => 4,
    :username => 8
  }

  def available_fields
    Field_bitmask.keys
  end

  def calc_mask(fields)
    mask = 0
    fields.each do |f|
      mask |= Field_bitmask[f]
    end
    mask
  end

  def basic_search(pattern, mask)
    SuffixTreeSingleton.instance.basic_search(pattern, mask)
  end

  def insert_post(post_id)
    post = Post.find post_id
    if post.nil?
      raise ArgumentError
    end
    available_fields.each do |f|
      SuffixTreeSingleton.instance.insert(post.send(f), Field_bitmask[f], post.id)
    end
    post.update(st_indexed: true)
  end

  def sync!
    SuffixTreeSingleton.instance.sync!
  end

  def sync_async
    SuffixTreeSingleton.instance.sync_async
  end

  def mark_functional
    SuffixTreeSingleton.instance.mark_functional
  end

  def mark_broken(reason)
    SuffixTreeSingleton.instance.mark_broken reason
  end

  def functional?
    SuffixTreeSingleton.instance.functional?
  end

  def broken_reason
    SuffixTreeSingleton.instance.broken_reason
  end
end
