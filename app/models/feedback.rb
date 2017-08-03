# frozen_string_literal: true

class Feedback < ApplicationRecord
  include Websocket
  include ActionView::Helpers::UrlHelper

  default_scope { where(is_invalidated: false, is_ignored: false) }
  scope(:ignored, -> { unscoped.where(is_ignored: true) })
  scope(:invalid, -> { unscoped.where(is_invalidated: true) })
  scope(:via_api, -> { unscoped.where.not(api_key: nil) })
  scope(:today, -> { where('created_at > ?', Date.today) })

  belongs_to :post
  belongs_to :user
  belongs_to :api_key

  before_save :check_for_user_assoc
  before_save :check_for_dupe_feedback

  after_save do
    if update_post_feedback_cache # if post feedback cache was changed
      if post.flagged? && post.is_fp
        SmokeDetector.send_message_to_charcoal "fp feedback on autoflagged post: [#{post.title}](//metasmoke.erwaysoftware.com/post/#{post_id})"
      end
    end
  end

  after_create do
    ActionCable.server.broadcast "posts_#{post_id}", feedback: FeedbacksController.render(locals: { feedback: self }, partial: 'feedback').html_safe
    feedback = FeedbacksController.render(locals: { feedback: self }, partial: 'feedback.json')
    ActionCable.server.broadcast 'api_feedback', feedback: JSON.parse(feedback)
  end

  # Drop a user's earlier feedback if it's not invalidated
  # and less than a day old

  after_create do
    next if user_id.nil?

    num_deleted = post.feedbacks.where(user_id: user_id)
                      .where('created_at > ?', 24.hours.ago)
                      .where.not(id: id)
                      .delete_all

    post.reload.update_feedback_cache if num_deleted > 0
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

  def send_to_chat(post, user)
    unless Feedback.where(post: post, feedback_type: feedback_type).where.not(id: id).exists?
      message = "#{feedback_type} by #{user.username}"
      unless post.id == Post.last.id
        message += " on [#{post.title}](#{post.link}) \\[[MS](#{url_for(controller: :posts, action: :show, id: post.id)})]"
      end
      ActionCable.server.broadcast 'smokedetector_messages', message: message
      true
    end
    false
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
