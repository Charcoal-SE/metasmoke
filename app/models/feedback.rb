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

  VALID_TYPES = %w[tp tpu fp fpu naa ignore]
                .map { |f| [f, "#{f}-"] }.flatten

  validates :feedback_type, inclusion: { in: VALID_TYPES }

  after_save :populate_redis
  after_commit :check_for_dupe_feedback_again

  def populate_redis
    redis.sadd "post/#{post.id}/feedbacks", id.to_s
    redis.hmset "feedbacks/#{id}", *{
      feedback_type: feedback_type,
      username: user.try(:username) || user_name,
      app_name: api_key.try(:app_name),
      invalidated: is_invalidated
    }
  end

  after_destroy :destroy_redis

  def destroy_redis
    redis.srem "post/#{post.id}/feedbacks", id.to_s
    redis.del "feedbacks/#{id}"
  end

  def self.populate_redis_meta
    keys = []
    prefix = 'feedbacks_populate'
    eager_load(:user).eager_load(:api_key).find_each(batch_size: 10_000) do |fb|
      redis.pipelined do
        next if fb.post_id.nil?
        key = "post/#{fb.post_id}/feedbacks"
        keys.push(key)
        redis.sadd "#{prefix}/#{key}", fb.id
        redis.hmset "feedbacks/#{fb.id}", *{
          feedback_type: fb.feedback_type,
          username: fb.user.try(:username) || fb.user_name,
          app_name: fb.api_key.try(:app_name),
          invalidated: fb.is_invalidated
        }
      end
    end
    redis.pipelined do
      keys.uniq.each do |key|
        redis.rename "#{prefix}/#{key}", key
      end
    end
  end

  after_save do
    if update_post_feedback_cache # if post feedback cache was changed
      if post.flagged? && !is_positive?
        message = "fp feedback on autoflagged post: [#{post.title}](#{post.link}) \\[[MS](//metasmoke.erwaysoftware.com/post/#{post_id})]"
        ActionCable.server.broadcast 'smokedetector_messages', autoflag_fp: { message: message, site: post.site.site_domain }

        Thread.new do
          names = post.flaggers.map { |u| '@' + u.username.tr(' ', '') }
          user_msg = "Autoflagged FP: flagged by #{names.join(', ')}"
          ActionCable.server.broadcast 'smokedetector_messages', autoflag_fp: { message: user_msg, site: post.site.site_domain }
          sys = User.find(-1)
          post.eligible_flaggers.each do |u|
            FlagCondition.validate_for_user(u, sys)
          end
        end
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

  after_create do
    DeletionLog.auto_other_flag(nil, post)
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
    return if Feedback.where(post: post).where('feedback_type LIKE ?', "#{feedback_type[0]}%").where.not(id: id).exists?

    message = "#{feedback_type} feedback received"
    unless post.id == Post.last.id
      host = 'metasmoke.erwaysoftware.com'
      link = url_helpers.url_for controller: :posts, action: :show, id: post.id, host: host
      message += " on \\[[MS](#{link})] [#{SmokeDetectorsHelper.escape_markdown post.title}](#{post.link})"
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

  def check_for_dupe_feedback_again
    duplicate = if user_id.present?
                  Feedback.where(user_id: user_id, post_id: post_id)
                else
                  Feedback.where(user_name: user_name, post_id: post_id)
                end.where.not(id: id).where(is_invalidated: false)
    return unless duplicate.exists?
    user = if user_id.present?
      User.find user_id
    else
      User.where(user_name: user_name)
    end
    duplicate.each do |d|
      if d.created_at > 1.day.ago
        d.destroy
      else
        d.update(is_invalidated: true, invalidated_by: user, invalidated_at: DateTime.now)
      end
    end
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
