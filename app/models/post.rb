# frozen_string_literal: true

class PostScrubber < Rails::Html::PermitScrubber
  def initialize
    super
    self.tags = %w[a b blockquote code del dd dl dt em h1 h2 h3 i img kbd li ol p pre s sup sub strong strike ul br hr]
    self.attributes = %w[href title src height width alt]
  end

  def skip_node?(node)
    node.text?
  end
end

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
           .includes(feedbacks: %i[user api_key]).includes(:comments)
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

  after_save :populate_redis
  after_destroy :remove_from_redis

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
      site_site_logo: site.try(:site_logo),
      stack_exchange_user_username: stack_exchange_user.try(:username),
      stack_exchange_user_id: stack_exchange_user.try(:id),
      flagged: flagged?,
      site_id: site_id,
      post_comments_count: comments.count,
      why: why
    }
    redis.hmset("posts/#{id}", *post.to_a)

    reason_names = reasons.map(&:reason_name)
    reason_weights = reasons.map(&:weight)
    redis.zadd("posts/#{id}/reasons", reason_weights.zip(reason_names)) unless reasons.empty?

    feedbacks.each(&:populate_redis)
    deletion_logs.each(&:update_deletion_data)

    reasons.each do |reason|
      redis.sadd "reasons/#{reason.id}", id
    end

    redis.sadd 'all_posts', id
    redis.zadd 'posts', created_at.to_i, id

    redis.sadd 'tps', id if is_tp
    redis.sadd 'fps', id if is_fp
    redis.sadd 'naas', id if is_naa
    if link.nil?
      redis.sadd 'nolink', id
    else
      redis.sadd 'questions', id if question?
      redis.sadd 'answers', id if answer?
    end
    redis.sadd 'autoflagged', id if flagged?
    redis.sadd 'deleted', id unless deleted_at.nil?
    redis.sadd "sites/#{site_id}/posts", id
  end

  def remove_from_redis
    redis.del "posts/#{id}"
    redis.del "posts/#{id}/reasons"
    # Test this one:
    Reason.find_each do |reason|
      redis.srem "reasons/#{reason.id}", id
    end
    redis.srem 'all_posts', id
    redis.zrem 'posts', id
    redis.srem 'tps', id
    redis.srem 'fps', id
    redis.srem 'naas', id
    redis.srem 'nolink', id
    redis.srem 'questions', id
    redis.srem 'answers', id
    redis.srem 'autoflagged', id
    redis.srem 'deleted', id
    redis.srem "sites/#{site_id}/posts", id
  end

  def self.populate_redis_meta
    progressbar = ProgressBar.create total: Post.count
    ilevel = ActiveRecord::Base.logger.level
    ActiveRecord::Base.logger.level = 1
    Post.all.eager_load(:reasons).eager_load(:flag_logs).find_each(batch_size: 50_000) do |post|
      # tps, fps, naas, reasons/id, questions, answers, autoflagged
      redis.pipelined do
        redis.sadd 'tps', post.id if post.is_tp
        redis.sadd 'fps', post.id if post.is_fp
        redis.sadd 'naas', post.id if post.is_naa
        post.reasons.each do |reason|
          redis.sadd "reasons/#{reason.id}", post.id
        end
        if post.link.nil?
          redis.sadd 'nolink', post.id
        else
          redis.sadd 'questions', post.id if post.question?
          redis.sadd 'answers', post.id if post.answer?
        end
        redis.sadd 'autoflagged', post.id if post.flagged?
        redis.sadd "sites/#{post.site_id}/posts", post.id
        redis.sadd 'all_posts', post.id
        redis.sadd 'deleted', post.id unless post.deleted_at.nil?
        redis.zadd 'posts', post.created_at.to_i, post.id
      end
      progressbar.increment
    end
    ActiveRecord::Base.logger.level = ilevel
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

  def reason_weight
    @weight ||= reasons.pluck(:weight).reduce(:+)
  end

  def user_reputation
    @poster_rep ||= stack_exchange_user.reputation
  end

  def reason_count
    @reason_count ||= reasons.count
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
    hosts = part_to_extract_from_domains.map do |uri|
      begin
        # Escape (URI-encode) hostname first, otherwise we get "URI must be ascii-only" on cases like
        # hxxps://supplémentsavis.fr/spammy-products-here
        regexed_hostname = uri.match(%r{(?<=\/\/)[^\/]+})&.try(:[], 0)
        uri = uri.gsub(regexed_hostname, CGI.escape(regexed_hostname))

        # DON'T unescape anything before parsing it, or we get "bad URI(is not URI?)"
        hostname = URI.parse(uri).hostname

        # Now unescape (URI-decode) the parsed hostname, otherwise we create domains that look like
        # hxxps://suppl%C3%A9mentsavis.fr/ (see #615)
        CGI.unescape(hostname).gsub(/www\./, '').downcase
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

  def self.scrubber
    PostScrubber.new
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
