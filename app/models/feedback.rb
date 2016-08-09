class Feedback < ApplicationRecord
  default_scope { where(is_invalidated: false, is_ignored: false) }

  belongs_to :post
  belongs_to :user
  belongs_to :api_key
  
  before_save :check_for_dupe_feedback
  before_save :check_for_user_assoc

  after_save do
    if self.update_post_feedback_cache # if post feedback cache was changed
      if self.api_key.present?
        # ActionCable.server.broadcast "smokedetector_messages", { :message => "Received feedback (#{self.feedback_type}) from #{self.user.username} on #{self.post_id} via API application #{self.api_key.app_name}." }
      end
    end
  end
  after_create do
    ActionCable.server.broadcast "posts_#{self.post_id}", { feedback: FeedbacksController.render(locals: {feedback: self}, partial: 'feedback').html_safe }
  end

  def is_positive?
    self.feedback_type.include? "t"
  end

  def is_negative?
    self.feedback_type.include? "f"
  end

  def is_naa?
    self.feedback_type.include? "naa"
  end

  def self.ignored
    self.unscoped.where(:is_ignored => true)
  end

  def self.invalid
    self.unscoped.where(:is_invalidated => true)
  end
  
  def self.via_api
    self.unscoped.where.not(:api_key => nil)
  end


  def update_post_feedback_cache
    if self.changed?
      return self.post.reload.update_feedback_cache # Returns whether the post feedback cache has been changed
    end
    return false
  end

  # This is a really ugly way to do this, but it's fast and slightly
  # less ugly than the alternatives I can come up with

  def element_class
    case
      when self.is_negative?
        "text-danger"
      when self.is_positive?
        "text-success"
      else
        ""
    end
  end

  def element_symbol
    case
      when self.is_negative?
        "&#x2717;"
      when self.is_positive?
        "&#x2713;"
      when self.is_naa?
        "&#128169;"
      else
        ""
    end
  end

  def select_without_nil
    select(Feedback.attribute_names - ['message_link'])
  end
  
  private
    def check_for_dupe_feedback
      duplicate = if self.user_id.present?
        Feedback.where(:user_id => self.user_id, :post_id => self.post_id, :feedback_type => self.feedback_type).where.not(:id => self.id)
      else
        Feedback.where(:user_name => self.user_name, :post_id => self.post_id, :feedback_type => self.feedback_type).where.not(:id => self.id)
      end

      if duplicate.exists?
        throw :abort
      end
    end

    def check_for_user_assoc
      return if chat_host.nil? or chat_user_id.nil?

      chat_id_field = case chat_host
      when "stackexchange.com"
        :stackexchange_chat_id
      when "stackoverflow.com"
        :stackoverflow_chat_id
      when "meta.stackexchange.com"
        :meta_stackexchange_chat_id
      else
        nil
      end

      return unless chat_id_field

      self.user = User.where(chat_id_field => chat_user_id).try(:first)
    end
end
