# frozen_string_literal: true

class Post < ApplicationRecord
  include Websocket

  validate :reject_recent_duplicates
  validates :link, format: { with: %r{\A\/\/(.*?)\/(questions|a)\/(\d+)\Z} }

  serialize :tags, JSON

  has_and_belongs_to_many :reasons
  has_and_belongs_to_many :post_tags, class_name: 'DomainTag'
  has_many :feedbacks, dependent: :destroy
  has_many :deletion_logs, dependent: :destroy
  belongs_to :site
  belongs_to :stack_exchange_user
  belongs_to :smoke_detector
  has_many :flag_logs, dependent: :destroy
  has_many :flags, dependent: :destroy
  has_and_belongs_to_many :spam_domains
  has_one :review_item, as: :reviewable
  has_many :comments, class_name: 'PostComment', dependent: :destroy
  has_many :abuse_reports, as: :reportable

  scope(:includes_for_post_row, -> do
    includes(:stack_exchange_user).includes(:reasons).includes(:site)
           .includes(feedbacks: [:user, :api_key]).includes(:comments)
  end)
  scope(:without_feedback, -> { where(feedbacks_count: 0).or(where(feedbacks_count: nil)) })
  scope(:unreviewed, -> { where('feedbacks_count < 2 or feedbacks_count is null') })

  scope(:autoflagged, -> { where(autoflagged: true) })
  scope(:not_autoflagged, -> { where(autoflagged: false) })

  scope(:today, -> { where('created_at > ?', Date.today) })

  scope(:tp, -> { where(is_tp: true) })
  scope(:fp, -> { where(is_fp: true) })
  scope(:naa, -> { where(is_naa: true) })

  scope(:undeleted, -> { where(deleted_at: nil) })

  after_commit do
    if review_item.present? && should_dq?(ReviewQueue['posts'])
      review_item.update(completed: true)
    end
  end

  after_commit :parse_domains, on: :create

  after_create do
    match = %r{\/(?:q(?:uestions)?|a(?:nswers)?)\/(\d+)}.match(link)
    update(native_id: match[1]) if match
  end

  after_create do
    ActionCable.server.broadcast 'posts_realtime', row: PostsController.render(locals: { post: Post.last }, partial: 'post').html_safe
    ActionCable.server.broadcast 'topbar', review: ReviewItem.active.count
  end

  def autoflag
    Rails.logger.warn "[autoflagging] #{id}: Post#autoflag begin"
    return 'Duplicate post' unless Post.where(link: link).count == 1
    return 'Flagging disabled' unless FlagSetting['flagging_enabled'] == '1'
    Rails.logger.warn "[autoflagging] #{id}: not a dupe"

    dry_run = FlagSetting['dry_run'] == '1'
    post = self

    begin
      conditions = post.site.flag_conditions.where(flags_enabled: true)
      available_user_ids = {}
      conditions.each do |condition|
        if condition.validate!(post)
          available_user_ids[condition.user.id] = condition
        end
      end
      Rails.logger.warn "[autoflagging] #{id}: fetched conditions"

      uids = post.site.user_site_settings.where(user_id: available_user_ids.keys).map(&:user_id)
      users = User.where(id: uids, flags_enabled: true).where.not(encrypted_api_token: nil)
      if users.blank?
        Rails.logger.warn "[autoflagging] #{id}: no users available"
        post.send_not_autoflagged
        return 'No users eligible to flag'
      end

      Rails.logger.warn "[autoflagging] #{id}: before revision count"
      post.fetch_revision_count
      unless post.revision_count == 1
        Rails.logger.warn "[autoflagging] #{id}: vandalized"
        post.send_not_autoflagged
        return 'More than one revision'
      end

      Rails.logger.warn "[autoflagging] #{id}: lottery begin"

      # Defined by the scaled_max_flags FlagSetting
      # scaled_max_flags = 0,0,0,99.9,99.99,101 would always allow 3 flags,
      # 4 flags on 99.9% accuracy, and 5 flags on 99.99% accuracy.
      # 101% means six flags is never allowed
      scaled_maxes = FlagSetting['scaled_max_flags']&.split(',')
      Rails.logger.warn "[autoflagging] #{id}: scaled maxes: #{scaled_maxes}"
      if !scaled_maxes.nil? && scaled_maxes.count == 6
        # Check historical accuracy
        fake_flag_condition = FlagCondition.new(
          sites: Site.mains,
          max_poster_rep: post.user_reputation,
          min_reason_count: 1,
          min_weight: post.reasons.sum(&:weight)
        )

        accuracy = fake_flag_condition.accuracy # Decimal number, like 99.8

        # If the accuracy is higher than all 6 thresholds (indicating 6 flags), index will be null
        scaled_max = scaled_maxes.index { |n| n.to_f > accuracy } || FlagSetting['max_flags'].to_i
      else
        scaled_max = FlagSetting['max_flags'].to_i
      end

      max_flags = [post.site.max_flags_per_post, (FlagSetting['max_flags'] || '3').to_i, scaled_max].min

      # Send the first flag with Smokey's account; shows up nicely in the flag queue / timeline
      # At this stage, we know that at least one user has a matching flag_condition (thus 99.x% accuracy)

      max_flags -= post.send_autoflag(User.smokey, dry_run, nil) unless User.smokey.nil?

      core_count = (max_flags / 2.0).ceil
      other_count = max_flags - core_count

      core_users_used = []
      Rails.logger.warn "[autoflagging] #{id}: core..."
      users.with_role(:core).shuffle.each do |user|
        break if core_count <= 0
        core_count -= post.send_autoflag(user, dry_run, available_user_ids[user.id])
        core_users_used << user
      end

      Rails.logger.warn "[autoflagging] #{id}: plebs..."
      # Go through all non-core users first; then add core users at the end. See #146
      ((users.without_role(:core).shuffle + users.with_role(:core).shuffle) - core_users_used).each do |user|
        break if other_count <= 0
        other_count -= post.send_autoflag(user, dry_run, available_user_ids[user.id])
      end
    rescue => e
      Rails.logger.warn "[autoflagging] #{id}: exception #{e} :("
      FlagLog.create(success: false, error_message: "#{e}: #{e.message} | #{e.backtrace.join("\n")}",
                     is_dry_run: dry_run, flag_condition: nil, post: post,
                     site_id: post.site_id)

      # Re-raise if we're in test, 'cause it shouldn't be throwing in test
      raise if Rails.env.test?
    end

    if post.flag_logs.where(success: true).empty?
      post.send_not_autoflagged
    else
      post.update_columns(autoflagged: true)
    end
  end

  def send_autoflag(user, dry_run, condition)
    Rails.logger.warn "[autoflagging] #{id}: send_autoflag begin: #{user.username}"
    user_site_flag_count = user.flag_logs.where(site: site, success: true, is_dry_run: false).where(created_at: Date.today..Time.now).count
    return 0 if user_site_flag_count >= (user.user_site_settings.includes(:sites).where(sites: { id: site.id }).minimum(:max_flags) || -1)
    Rails.logger.warn "[autoflagging] #{id}: has enough flags"
    last_log = FlagLog.auto.where(user: user).last
    if last_log.try(:backoff).present? && (last_log.created_at + last_log.backoff.seconds > Time.now)
      Rails.logger.warn "[autoflagging] #{id}: flag settings backoff..."
      sleep((last_log.created_at + last_log.backoff.seconds) - Time.now)
    end

    Rails.logger.warn "[autoflagging] #{id}: pre spam_flag"
    success, message = user.spam_flag(self, dry_run)
    Rails.logger.warn "[autoflagging] #{id}: post spam_flag"
    backoff = 0
    backoff = message if success

    unless [
      'Flag options not present',
      'Spam flag option not present',
      'You do not have permission to flag this post',
      'No account on this site.',
      'User is a moderator on this site'
    ].include? message
      flag_log = FlagLog.create(success: success, error_message: message,
                                is_dry_run: dry_run, flag_condition: condition,
                                user: user, post: self, backoff: backoff,
                                site_id: site_id)

      if success
        Rails.logger.warn "[autoflagging] #{id}: send_autoflagged..."
        log_as_json = JSON.parse(FlagLogController.render(locals: { flag_log: flag_log }, partial: 'flag_log.json'))
        ActionCable.server.broadcast 'api_flag_logs', flag_log: log_as_json
        ActionCable.server.broadcast 'flag_logs', row: FlagLogController.render(locals: { log: flag_log }, partial: 'flag_log')
        Rails.logger.warn "[autoflagging] #{id}: broadcast"
      end
    end

    success ? 1 : 0
  end

  def send_not_autoflagged
    Rails.logger.warn "[autoflagging] #{id}: send_not_autoflagged..."
    ActionCable.server.broadcast 'api_flag_logs', not_flagged: {
      post_link: link,
      post: JSON.parse(PostsController.render(locals: { post: self }, partial: 'post.json'))
    }
    Rails.logger.warn "[autoflagging] #{id}: broadcast"
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

  def is_question? # rubocop:disable Style/PredicateName
    link.include? '/questions/'
  end

  def is_answer? # rubocop:disable Style/PredicateName
    link.include? '/a/'
  end

  def is_deleted? # rubocop:disable Style/PredicateName
    deletion_logs.where(is_deleted: true).any?
  end

  def stack_id
    link.scan(/(\d*)$/).first.first.to_i
  end

  def flagged?
    if flag_logs.loaded?
      flag_logs.select { |f| f.success && f.is_auto }.present?
    else
      flag_logs.where(success: true, is_auto: true).present?
    end
  end

  def flaggers
    User.joins(:flag_logs).where(flag_logs: { success: true, post_id: id, is_auto: true })
  end

  def manual_flaggers
    User.joins(:flag_logs).where(flag_logs: { success: true, post_id: id, is_auto: false })
  end

  def fetch_revision_count(post = nil)
    Rails.logger.warn "[autoflagging] #{id}: fetch_revision_count begin"
    post ||= self
    return if post.site.blank?
    Rails.logger.warn "[autoflagging] #{id}: site was present"
    params = "key=#{AppConfig['stack_exchange']['key']}&site=#{post.site.site_domain}&filter=!mggE4ZSiE7"

    url = "https://api.stackexchange.com/2.2/posts/#{post.stack_id}/revisions?#{params}"
    revision_list = JSON.parse(Net::HTTP.get_response(URI.parse(url)).body)['items']
    Rails.logger.warn "[autoflagging] #{id}: queried SE: #{revision_list&.count}"

    update(revision_count: revision_list.count)
    revision_list.count
  end

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
    hosts = (URI.extract(body || '') + URI.extract(title || '')).map do |x|
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
    end
  end

  def custom_review_action(_queue, _item, user, response)
    feedbacks.create(user: user, feedback_type: response)
  end

  def should_dq?(queue)
    case queue.name
    when 'posts'
      feedbacks.count >= 2
    else
      false
    end
  end

  def review_item_name
    title
  end
end
