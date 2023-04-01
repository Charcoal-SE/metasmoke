# frozen_string_literal: true

class SpamWave < ApplicationRecord
  belongs_to :user
  has_and_belongs_to_many :sites

  serialize :conditions, JSON

  validates :name, presence: true
  validates :max_flags, numericality: { greater_than_or_equal_to: 1, less_than_or_equal_to: 6 }
  validate :check_min_accuracy
  validate :max_expiry

  scope(:active, -> { where('expiry >= ?', DateTime.now) })
  scope(:expired, -> { where('expiry < ?', DateTime.now) })

  # The regex_cache won't be consistent across threads, but we don't need it
  # to be. We only need it to not be corrupted from uses across threads, which it
  # shouldn't be, as threads don't share class variables.
  #
  # In addition, a Rails.cache entry is created for each Regexp. That entry should
  # be available across threads, but will be a bit slower due to the
  # serialization/deserialization steps.
  @@regex_cache = {} # rubocop:disable Style/ClassVars
  MAX_REGEX_CACHE_SIZE = 100

  def post_matches?(post, site_ids = nil)
    Rails.logger.debug "[spam-wave] id: #{id}: #{name}:: post_matches?: post id: #{post.id}: #{post.title}"
    site_ids = site_ids.nil? ? sites.map(&:id) : site_ids
    matches = []
    matches << site_ids.include?(post.site_id)
    if conditions['max_user_rep'].present?
      matches << (post.user_reputation <= conditions['max_user_rep'].to_i)
    end

    # If everything doesn't already match, there's no reason to run the regex tests.
    return false unless matches.all?

    %w[username title body].each do |f|
      Rails.logger.debug "[spam-wave] id: #{id}: #{name}:: post_matches?: #{f}: post id: #{post.id}: #{post.title}"
      # Try using an already existing regex from the regex_cache.
      regex_text = conditions["#{f}_regex"]
      Rails.logger.debug "[spam-wave] id: #{id}: #{name}:: #{f}_regex.encoding: #{regex_text.encoding}"
      regex = @@regex_cache[regex_text]
      if regex.nil?
        # There wasn't an entry in the regex_cache for this regex text, so check Rails.cache.
        Rails.logger.debug "[spam-wave] id: #{id}: #{name}:: regex_cache miss: checking Rails.cache #{f}_regex"
        regex = Rails.cache.fetch("SPAM_WAVE_REGEXP_CACHE: #{regex_text}", expires_in: 6.hours) do
          # There's no entry for the regex in Rails.cache, so create it.
          Rails.logger.debug "[spam-wave] id: #{id}: #{name}:: Rails.cache: REGEXP_CACHE miss: compiling #{f}_regex"
          Regexp.new(regex_text)
        end
        Rails.logger.debug "[spam-wave] id: #{id}: #{name}:: #{f}_regex compiled or in Rails.cache"
        @@regex_cache[regex_text] = regex
        if @@regex_cache.length > MAX_REGEX_CACHE_SIZE
          # There are too many entries in the regex_cache, so delete the least recent two.
          # This is only sufficient because this is the only place where we're adding to the cache.
          # If the regex_cache is to be interacted with in more than this method, then we should
          # break the regex_cache out at least into its own methods, if not into its own class.
          regex_cache_keys = @@regex_cache.keys
          @@regex_cache.delete regex_cache_keys[0]
          @@regex_cache.delete regex_cache_keys[1]
        end
      end
      # We only care about everything matching.
      # Returning here saves testing the longer strings if a shorter one doesn't match.
      post_text = post.send(f.to_sym)
      post_text = '' if post_text.nil?
      # UTF-8 -> UTF-16 -> UTF-8 idea and code from [answer to: "ruby 1.9: invalid byte sequence in UTF-8"](https://stackoverflow.com/a/8873922)
      # by [RubenLaguna](https://stackoverflow.com/users/90580/rubenlaguna), which is under a CC BY-SA 3.0 license.
      post_text.encode!('UTF-16', 'UTF-8', invalid: :replace, replace: '')
      post_text.encode!('UTF-8', 'UTF-16')
      Rails.logger.debug "[spam-wave] id: #{id}: #{name}:: post #{f}: encoding: #{post_text.encoding}"
      return false unless regex.match?(post_text)
      Rails.logger.debug "[spam-wave] id: #{id}: #{name}:: post_matches?: #{f}: MATCHES: post id: #{post.id}: #{post.title}"
    end

    # If we get here, then everything matches. We've already tested matches.all? for the
    # non-regex conditions, and we return immediately if any of the regexes don't match.
    true
  end

  def posts_matching_sites_and_reputation
    site_ids = sites.map(&:id)
    posts = Post.where('created_at >= ?', created_at - 1.month).where(site_id: site_ids)
    if conditions['max_user_rep'].present?
      posts = posts.where('user_reputation <= ?', conditions['max_user_rep'])
    end
    Rails.logger.debug "[spam-wave] id: #{id}: #{name}:: posts_matching_site_and_reputation.size: #{posts.size}"
    posts
  end

  def posts
    site_ids = sites.map(&:id)
    filtered_count = 0
    posts_to_be_filtered = posts_matching_sites_and_reputation
    posts_to_be_filtered_size = posts_to_be_filtered.size
    posts_to_be_filtered.select do |p|
      filtered_state = "(#{filtered_count}/#{posts_to_be_filtered_size})"
      Rails.logger.debug "[spam-wave] id: #{id}: #{name}:: filtering: #{filtered_state}: post id: #{p.id}: #{p.title}"
      matches_result = post_matches?(p, site_ids)
      filtered_count += 1
      filtered_state = "(#{filtered_count}/#{posts_to_be_filtered_size})"
      Rails.logger.debug "[spam-wave] id: #{id}: #{name}:: filtered: #{filtered_state}: result: #{matches_result}: post id: #{p.id}: #{p.title}"
      matches_result
    end
  end

  def accuracy
    tps = posts.select(&:is_tp)
    (tps.size.to_f / posts.size) * 100
  end

  protected

  def check_min_accuracy
    post_count = SiteSetting['min_wave_post_count']
    min_accuracy = SiteSetting['min_wave_accuracy']
    return if accuracy >= min_accuracy && posts.count >= post_count
    errors.add(:conditions, "must result in post count >= #{post_count} and accuracy >= #{min_accuracy}")
  end

  def max_expiry
    return if expiry <= 2.day.from_now
    errors.add(:expiry, 'must be no more than 48 hours from now')
  end
end
