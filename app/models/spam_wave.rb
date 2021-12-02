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

  def post_matches?(post, site_ids = nil)
    site_ids = site_ids.nil? ? sites.map(&:id) : site_ids
    matches = []
    matches << site_ids.include?(post.site_id)
    if conditions['max_user_rep'].present?
      matches << (post.user_reputation <= conditions['max_user_rep'].to_i)
    end

    %w[title body username].each do |f|
      matches << !Regexp.new(conditions["#{f}_regex"]).match(post.send(f.to_sym)).nil?
    end

    matches.all?
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
    return if expiry <= 1.day.from_now
    errors.add(:expiry, 'must be no more than 24 hours from now')
  end
end
