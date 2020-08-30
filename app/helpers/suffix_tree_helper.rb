# frozen_string_literal: true

require 'singleton'

module SuffixTreeHelper
  class SuffixTreeSingleton < SuffixTree
    include Singleton
    def initialize
      super(AppConfig['suffix_tree']['str_path'], AppConfig['suffix_tree']['tag_path'],
            AppConfig['suffix_tree']['child_path'], AppConfig['suffix_tree']['node_path'])
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
    fields.reduce(0) do |mask, field|
      mask | field
    end
  end

  def self.basic_search(pattern, mask)
    SuffixTreeSingleton.instance.basic_search(pattern.unicode_normalize.encode('utf-8'), mask)
  end

  def self.insert_post(post_id)
    post = Post.find post_id
    raise ArgumentError if post.nil?
    available_fields.each do |f|
      SuffixTreeSingleton.instance.insert(post[f].unicode_normalize.encode('utf-8'), FIELD_BITMASK[f], post.id)
    end
    post.update(st_indexed: true)
  end

  %i[sync! mark_functional mark_broken functional? broken_reason].each do |m|
    define_singleton_method(m) { SuffixTreeSingleton.instance.send(m) }
  end
end
