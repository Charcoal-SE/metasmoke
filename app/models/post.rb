# frozen_string_literal: true

class Post < ApplicationRecord
  validate :reject_recent_duplicates

  has_and_belongs_to_many :reasons
  has_many :feedbacks, dependent: :destroy
  has_many :deletion_logs, dependent: :destroy
  belongs_to :site
  belongs_to :stack_exchange_user
  belongs_to :smoke_detector
  has_many :flag_logs, dependent: :destroy
  has_many :flags, dependent: :destroy

  scope(:includes_for_post_row, -> { includes(:stack_exchange_user).includes(:reasons).includes(feedbacks: [:user, :api_key]) })
  scope(:without_feedback, -> { left_joins(:feedbacks).where(feedbacks: { post_id: nil }) })

  scope(:autoflagged, -> { includes(:flag_logs).where(flag_logs: { is_auto: true }).where.not(flag_logs: { id: nil }) })

  scope(:not_autoflagged, lambda {
    left_joins(:flag_logs).where('flag_logs.id IS NULL OR flag_logs.is_auto = 0')
  })

  after_create do
    ActionCable.server.broadcast 'posts_realtime', row: PostsController.render(locals: { post: Post.last }, partial: 'post').html_safe
    ActionCable.server.broadcast 'topbar', review: Post.without_feedback.count
  end

  after_create do
    post = self
    Thread.new do
      # Trying to autoflag in a different thread while in test
      # can cause race conditions and segfaults. This is bad,
      # so we completely suppress the issue and just don't do that.
      post.autoflag unless Rails.env.test?
    end
  end

  def autoflag
    return 'Duplicate post' unless Post.where(link: link).count == 1
    return 'Flagging disabled' unless FlagSetting['flagging_enabled'] == '1'

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

      uids = post.site.user_site_settings.where(user_id: available_user_ids.keys).map(&:user_id)
      users = User.where(id: uids, flags_enabled: true).where.not(encrypted_api_token: nil)
      unless users.present?
        post.send_not_autoflagged
        return 'No users eligible to flag'
      end

      post.fetch_revision_count
      unless post.revision_count == 1
        post.send_not_autoflagged
        return 'More than one revision'
      end

      max_flags = [post.site.max_flags_per_post, (FlagSetting['max_flags'] || '3').to_i].min
      core_count = (max_flags / 2.0).ceil
      other_count = max_flags - core_count

      core_users_used = []

      users.with_role(:core).shuffle.each do |user|
        break if core_count <= 0
        core_count -= post.send_autoflag(user, dry_run, available_user_ids[user.id])
        core_users_used << user
      end

      # Go through all non-core users first; then add core users at the end. See #146
      ((users.without_role(:core).shuffle + users.with_role(:core).shuffle) - core_users_used).each do |user|
        break if other_count <= 0
        other_count -= post.send_autoflag(user, dry_run, available_user_ids[user.id])
      end
    rescue => e
      FlagLog.create(success: false, error_message: "#{e}: #{e.message} | #{e.backtrace.join("\n")}",
                     is_dry_run: dry_run, flag_condition: nil, post: post,
                     site_id: post.site_id)

      # Re-raise if we're in test, 'cause it shouldn't be throwing in test
      raise if Rails.env.test?
    end

    post.send_not_autoflagged if post.flag_logs.where(success: true).empty?
  end

  def send_autoflag(user, dry_run, condition)
    user_site_flag_count = user.flag_logs.where(site: site, success: true, is_dry_run: false).where(created_at: Date.today..Time.now).count
    return 0 if user_site_flag_count >= user.user_site_settings.includes(:sites).where(sites: { id: site.id }).minimum(:max_flags)

    last_log = FlagLog.auto.where(user: user).last
    if last_log.try(:backoff).present? && (last_log.created_at + last_log.backoff.seconds > Time.now)
      sleep((last_log.created_at + last_log.backoff.seconds) - Time.now)
    end

    success, message = user.spam_flag(self, dry_run)
    backoff = 0
    backoff = message if success

    unless [
      'Flag options not present',
      'Spam flag option not present',
      'You do not have permission to flag this post',
      'No account on this site.'
    ].include? message
      flag_log = FlagLog.create(success: success, error_message: message,
                                is_dry_run: dry_run, flag_condition: condition,
                                user: user, post: self, backoff: backoff,
                                site_id: site_id)

      if success
        log_as_json = JSON.parse(FlagLogController.render(locals: { flag_log: flag_log }, partial: 'flag_log.json'))
        ActionCable.server.broadcast 'api_flag_logs', flag_log: log_as_json
        ActionCable.server.broadcast 'flag_logs', row: FlagLogController.render(locals: { log: flag_log }, partial: 'flag_log')
      end
    end

    success ? 1 : 0
  end

  def send_not_autoflagged
    ActionCable.server.broadcast 'api_flag_logs', not_flagged: {
      post_link: link,
      post: JSON.parse(PostsController.render(locals: { post: self }, partial: 'post.json'))
    }
  end

  def reject_recent_duplicates
    # If a different SmokeDetector has reported the same post in the last 5 minutes, reject it

    return unless respond_to?(:smoke_detector_id) && smoke_detector.present?

    conflict = Post.where(link: link)
                   .where('created_at > ?', 5.minutes.ago)
                   .where.not(smoke_detector: smoke_detector)
                   .last

    return unless conflict.present?

    errors.add(:base, "Reported in the last 5 minutes by a different instance: #{conflict.id}")
  end

  def update_feedback_cache
    self.is_tp = false
    self.is_fp = false

    feedbacks = self.feedbacks.to_a

    self.is_tp = true if feedbacks.index(&:is_positive?)
    self.is_fp = true if feedbacks.index(&:is_negative?)
    self.is_naa = true if feedbacks.index(&:is_naa?)

    is_feedback_changed = is_tp_changed? || is_fp_changed? || is_naa_changed?

    save!

    if is_tp && is_fp
      SmokeDetector.send_message_to_charcoal "Conflicting feedback on [#{title}](//metasmoke.erwaysoftware.com/post/#{id})."
    end

    if is_fp_changed? && is_fp && flagged?
      SmokeDetector.send_message_to_charcoal "**fp on autoflagged post**: #{title}](//metasmoke.erwaysoftware.com/post/#{id})"
    end

    if is_feedback_changed
      ActionCable.server.broadcast 'topbar', review: Post.without_feedback.count
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
    post ||= self
    params = "key=#{AppConfig['stack_exchange']['key']}&site=#{post.site.site_domain}&filter=!mggE4ZSiE7"

    url = "https://api.stackexchange.com/2.2/posts/#{post.stack_id}/revisions?#{params}"
    revision_list = JSON.parse(Net::HTTP.get_response(URI.parse(url)).body)['items']

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
end
