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

  FIELD_BITMASK = {
    title: 1,
    body: 2,
    why: 4,
    username: 8
  }.freeze

  def self.available_fields
    FIELD_BITMASK.keys
  end

  def self.calc_mask(fields)
    mask = 0
    fields.each do |f|
      mask |= FIELD_BITMASK[f]
    end
    mask
  end

  def self.basic_search(pattern, mask)
    SuffixTreeSingleton.instance.basic_search(pattern, mask)
  end

  def self.insert_post(post_id)
    post = Post.find post_id
    post.nil? && raise ArgumentError
    available_fields.each do |f|
      SuffixTreeSingleton.instance.insert(post.send(f), FIELD_BITMASK[f], post.id)
    end
    post.update(st_indexed: true)
  end

  def self.sync!
    SuffixTreeSingleton.instance.sync!
  end

  def self.sync_async
    SuffixTreeSingleton.instance.sync_async
  end

  def self.mark_functional
    SuffixTreeSingleton.instance.mark_functional
  end

  def self.mark_broken(reason)
    SuffixTreeSingleton.instance.mark_broken reason
  end

  def self.functional?
    SuffixTreeSingleton.instance.functional?
  end

  def self.broken_reason
    SuffixTreeSingleton.instance.broken_reason
  end
end
