# frozen_string_literal: true

class Post < ApplicationRecord
  include Websocket
  include PostConcerns::Autoflagging
  include PostConcerns::Review

  validate :reject_recent_duplicates
  validates :link, format: { with: %r{\A\/\/(.*?)\/(questions|a)\/(\d+)\Z} }, allow_blank: true, on: :create

  serialize :tags, JSON

  belongs_to :site
  belongs_to :stack_exchange_user
  belongs_to :smoke_detector
  has_and_belongs_to_many :reasons
  has_and_belongs_to_many :post_tags, class_name: 'DomainTag'
  has_and_belongs_to_many :spam_domains
  has_many :feedbacks, dependent: :destroy
  has_many :deletion_logs, dependent: :destroy
  has_many :flag_logs, dependent: :destroy
  has_many :flags, dependent: :destroy
  has_many :comments, class_name: 'PostComment', dependent: :destroy
  has_many :abuse_reports, as: :reportable
  has_one :review_item, as: :reviewable

  scope(:includes_for_post_row, -> do
    includes(:stack_exchange_user).includes(:reasons).includes(:site)
           .includes(feedbacks: [:user, :api_key]).includes(:comments)
  end)

  scope(:without_feedback, -> { where(feedbacks_count: 0).or(where(feedbacks_count: nil)) })

  scope(:today, -> { where('created_at > ?', Date.today) })

  scope(:tp, -> { where(is_tp: true) })
  scope(:fp, -> { where(is_fp: true) })
  scope(:naa, -> { where(is_naa: true) })

  scope(:undeleted, -> { where(deleted_at: nil) })

  after_commit :parse_domains, on: :create

  after_create do
    match = %r{\/(?:q(?:uestions)?|a(?:nswers)?)\/(\d+)}.match(link)
    update(native_id: match[1]) if match
  end

  after_create do
    ActionCable.server.broadcast 'posts_realtime', row: PostsController.render(locals: { post: Post.last }, partial: 'post').html_safe
    ActionCable.server.broadcast 'topbar', review: ReviewItem.active.count
  end

  def reject_recent_duplicates
    # If a different SmokeDetector has reported the same post in the last 5 minutes, reject it

    return unless respond_to?(:smoke_detector_id) && smoke_detector.present?

    conflict = Post.where(link: link)
                   .where('created_at > ?', 5.minutes.ago)
                   .where.not(smoke_detector: smoke_detector)
                   .last

    return if conflict.blank?

    errors.add(:base, "Reported in the last 5 minutes by a different instance: #{conflict.id}")
  end

  def populate_redis
    post = {
      body: body,
      title: title,
      reason_weight: reasons.map(&:weight).reduce(:+),
      created_at: created_at,
      username: username,
      link: link,
      site_site_logo: site.site_logo,
      stack_exchange_user_username: stack_exchange_user.try(:username),
      stack_exchange_user_id: stack_exchange_user.try(:id),
      flagged: flagged?,
      site_id: site_id,
      post_comments_count: comments.count
    }
    redis.hmset("posts/#{id}", *post.to_a)

    reason_names = reasons.map(&:reason_name)
    reason_weights = reasons.map(&:weight)
    redis.zadd("posts/#{id}/reasons", reason_weights.zip(reason_names)) unless reasons.empty?

    redis.zadd('posts', 0, id)
    feedbacks.each(&:populate_redis)
    deletion_logs.each(&:update_deletion_data)
  end

  def self.from_redis(id)
    post = Post.new
    rpost = redis.hgetall("posts/#{id}")
    post.body = rpost['body']
    post.title = rpost['title']
    post.link = rpost['link']
    post.created_at = rpost['created_at']
    post.username = rpost['username']
    post.site_id = rpost['site_id']
    post.stack_exchange_user = StackExchangeUser.new(username: rpost['stack_exchange_user_username'], id: rpost['stack_exchange_user_id'])
    post.comments = rpost["post_comments_count"].to_i.times.map { PostComment.new }
    post.comments.define_singleton_method(:count) { rpost["post_comments_count"].to_i }
    post.site = Site.new(site_logo: rpost['site_site_logo'])
    # Could do without this line.
    post.define_singleton_method(:flagged?) { rpost['flagged'] == 'true' ? true : false }
    reason_names = redis.zrange "posts/#{id}/reasons", 0, -1, with_scores: true
    post.reasons = reason_names.map do |rn, weight|
      Reason.new(reason_name: rn, weight: weight)
    end
    post.feedbacks = Feedback.from_redis(id)
    post.deletion_logs = DeletionLog.from_redis(id)
    post.deleted_at = post.deletion_logs.first.created_at unless post.deletion_logs.empty?
    # If we set the ID earlier, stuff explodes becaus AR thinks the record is real
    post.id = id
    post
  end

  def update_feedback_cache
    feedbacks = self.feedbacks.to_a

    self.is_tp = feedbacks.any?(&:is_positive?)
    self.is_fp = feedbacks.any?(&:is_negative?)
    self.is_naa = feedbacks.any?(&:is_naa?)

    is_feedback_changed = is_tp_changed? || is_fp_changed? || is_naa_changed?

    save!

    conflicting_revisions = Post.where(link: link)
                                .where.not(id: id)
                                .where('is_tp != ? or is_fp != ?', is_tp, is_fp)

    if conflicting_revisions.count > 0
      msg = "Conflicting feedback across revisions: [current](//metasmoke.erwaysoftware.com/post/#{id})"

      conflicting_revisions.each_with_index do |post, i|
        msg += ", [##{i + 1}](//metasmoke.erwaysoftware.com/post/#{post.id})"
      end

      # SmokeDetector.send_message_to_charcoal msg
    end

    if is_tp && is_fp
      # SmokeDetector.send_message_to_charcoal "Conflicting feedback on [#{title}](//metasmoke.erwaysoftware.com/post/#{id})."
    end

    if is_fp_changed? && is_fp && flagged?
      SmokeDetector.send_message_to_charcoal "**fp on autoflagged post**: #{title}](//metasmoke.erwaysoftware.com/post/#{id})"
    end

    if is_feedback_changed
      ActionCable.server.broadcast 'topbar', review: ReviewItem.active.count
    end

    is_feedback_changed
  end

  def question?
    link.include? '/questions/'
  end

  def answer?
    link.include? '/a/'
  end

  def deleted?
    deletion_logs.where(is_deleted: true).any?
  end

  def conflicted?
    is_tp && (is_fp || is_naa)
  end

  def stack_id
    native_id
  end

  # Called get_revision_count with the predicate because the model already has an attribute in the DB called revision_count.
  def get_revision_count # rubocop:disable Style/AccessorMethodName
    post = if respond_to? :revision_count
             self
           else
             Post.find id
           end

    if post.revision_count.present?
      post.revision_count
    else
      fetch_revision_count(respond_to?(:revision_count) ? nil : post)
    end
  end

  def parse_domains
    hosts = part_to_extract_from_domains.map do |x|
      begin
        URI.parse(x).hostname.gsub(/www\./, '').downcase
      rescue
        nil
      end
    end.compact.uniq

    hosts.each do |h|
      next if h.length >= 255
      domain = SpamDomain.find_or_create_by domain: h
      domain.posts << self unless domain.posts.include? self
      Rails.cache.delete "spam_domain_post_counts_##{domain.id}"
    end
  end

  private

  def part_to_extract_from_domains
    if answer?
      URI.extract(body || '')
    else
      (URI.extract(body || '') + URI.extract(title || ''))
    end
  end
end
