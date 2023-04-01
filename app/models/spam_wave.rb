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
    site_ids = site_ids.nil? ? sites.map(&:id) : site_ids
    matches = []
    matches << site_ids.include?(post.site_id)
    if conditions['max_user_rep'].present?
      matches << (post.user_reputation <= conditions['max_user_rep'].to_i)
    end

    # If everything doesn't already match, there's no reason to run the regex tests.
    return false unless matches.all?

    %w[username title body].each do |f|
      # Try using an already existing regex from the regex_cache.
      regex_text = conditions["#{f}_regex"]
      regex = @@regex_cache[regex_text]
      if regex_entry.nil?
        # There wasn't an entry in the regex_cache for this regex text, so check Rails.cache.
        Rails.logger.warn "[spam-wave] regex_cache miss: checking Rails.cache #{f}_regex for spam wave id: #{@id}: #{@name}"
        regex = Rails.cache.fetch("SPAM_WAVE_REGEXP_CACHE: #{regex_text}", expires_in: 6.hours) do
          # There's no entry for the regex in Rails.cache, so create it.
          Rails.logger.warn "[spam-wave] Rails.cache: REGEXP_CACHE miss: compiling #{f}_regex for spam wave id: #{@id}: #{@name}"
          Regexp.new(regex_text)
        end
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
      return false unless regex.match?(post.send(f.to_sym))
    end

    # If we get here, then everything matches. We've already tested matches.all? for the
    # non-regex conditions, and we return immediately if any of the regexes don't match.
    true
  end

  def unfiltered_posts
    site_ids = sites.map(&:id)
    posts = Post.where('created_at >= ?', created_at - 1.month).where(site_id: site_ids)
    if conditions['max_user_rep'].present?
      posts = posts.where('user_reputation <= ?', conditions['max_user_rep'])
    end
    posts
  end

  def posts
    site_ids = sites.map(&:id)
    unfiltered_posts.select { |p| post_matches?(p, site_ids) }
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
