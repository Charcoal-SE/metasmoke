# frozen_string_literal: true

class Feedback < ApplicationRecord
  include Websocket
  delegate :url_helpers, to: 'Rails.application.routes'

  default_scope { where(is_invalidated: false) }
  scope(:invalid, -> { unscoped.where(is_invalidated: true) })
  scope(:via_api, -> { unscoped.where.not(api_key: nil) })
  scope(:today, -> { where('created_at > ?', Date.today) })

  belongs_to :post, counter_cache: true
  belongs_to :user
  belongs_to :invalidated_by, class_name: 'User', foreign_key: 'invalidated_by'
  belongs_to :api_key

  before_save :check_for_user_assoc
  before_save :check_for_dupe_feedback

  after_create :send_to_chat
  after_create :send_blacklist_request

  VALID_TYPES = %w[tp tpu fp fpu naa rude ignore]
                .map { |f| [f, "#{f}-"] }.flatten

  validates :feedback_type, inclusion: { in: VALID_TYPES }

  after_save do
    if update_post_feedback_cache # if post feedback cache was changed
      if post.flagged? && !post.is_tp
        flags = post.flag_logs.successful.where.not(user_id: -1).includes(:user)
        names = flags.map { |flag| '@' + flag.user.username.tr(' ', '') }

        flags.each do |flag|
          next unless flag.user.present?
          Thread.new do
            FlagCondition.validate_for_user(flag.user, User.find(-1))
          end
        end

        message = "fp feedback on autoflagged post: [#{post.title}](#{post.link}) [MS]" \
                  "(//metasmoke.erwaysoftware.com/post/#{post_id}) (#{names.join ' '})"
        ActionCable.server.broadcast 'smokedetector_messages', autoflag_fp: { message: message, site: post.site.site_domain }
      end

      post.stack_exchange_user&.unblacklist_user if post.is_fp
    end
  end

  after_create do
    ActionCable.server.broadcast "posts_#{post_id}", feedback: FeedbacksController.render(locals: { feedback: self }, partial: 'feedback').html_safe
    feedback = FeedbacksController.render(locals: { feedback: self }, partial: 'feedback.json')
    ActionCable.server.broadcast 'api_feedback', feedback: JSON.parse(feedback)

    update(user_name: user.username) if user_id.present? && user_name.nil?
  end

  # Drop a user's earlier feedback if it's not invalidated
  # and less than a day old

  after_create do
    next if user_id.nil?

    num_deleted = post.feedbacks.where(user_id: user_id)
                      .where('created_at > ?', 24.hours.ago)
                      .where.not(id: id)
                      .destroy_all

    post.reload.update_feedback_cache unless num_deleted.empty?
  end

  # Keep this block last to make sure any corrections or deletions have been made before we check count
  after_create do
    if post.feedbacks.count >= 2 && post.review_item&.completed == false
      post.review_item.update(completed: true)
    end
  end

  def is_positive? # rubocop:disable Style/PredicateName
    feedback_type.include? 't'
  end

  def is_negative? # rubocop:disable Style/PredicateName
    feedback_type.include? 'f'
  end

  def is_naa? # rubocop:disable Style/PredicateName
    feedback_type.include? 'naa'
  end

  def does_affect_user?
    feedback_type.ends_with?('u') || feedback_type.ends_with?('u-')
  end

  def update_post_feedback_cache
    if saved_changes?
      return post.reload.update_feedback_cache # Returns whether the post feedback cache has been changed
    end
    false
  end

  def select_without_nil
    select(Feedback.attribute_names - ['message_link'])
  end

  def send_to_chat
    return if chat_user_id.present?

    return if Feedback.where(post: post, feedback_type: feedback_type).where.not(id: id).exists?

    message = "#{feedback_type} by #{user&.username || user_name}"
    unless post.id == Post.last.id
      host = 'metasmoke.erwaysoftware.com'
      link = url_helpers.url_for controller: :posts, action: :show, id: post.id, host: host
      message += " on [#{SmokeDetectorsHelper.escape_markdown post.title}](#{post.link}) \\[[MS](#{link})]"
    end
    ActionCable.server.broadcast 'smokedetector_messages', message: message
  end

  def send_blacklist_request
    return if chat_user_id.present?

    return unless is_positive? && does_affect_user?

    post.stack_exchange_user&.blacklist_for_post(post)
  end

  private

  def check_for_dupe_feedback
    duplicate = if user_id.present?
                  Feedback.where(user_id: user_id, post_id: post_id, feedback_type: feedback_type).where.not(id: id)
                else
                  Feedback.where(user_name: user_name, post_id: post_id, feedback_type: feedback_type).where.not(id: id)
                end

    throw :abort if duplicate.exists? && !is_invalidated
  end

  def check_for_user_assoc
    return if chat_host.nil? || chat_user_id.nil?

    chat_id_field = case chat_host
                    when 'stackexchange.com'
                      :stackexchange_chat_id
                    when 'stackoverflow.com'
                      :stackoverflow_chat_id
                    when 'meta.stackexchange.com'
                      :meta_stackexchange_chat_id
                    end

    return unless chat_id_field

    self.user = User.where(chat_id_field => chat_user_id).try(:first)
  end
end
