class Feedback < ApplicationRecord
  default_scope { where(is_invalidated: false, is_ignored: false) }
  scope :ignored, where(:is_ignored => true)
  scope :invalid, where(:is_invalidated => true)

  belongs_to :post
  belongs_to :user
  after_save :update_post_feedback_cache

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


  def update_post_feedback_cache
    if self.changed?
      self.post.reload.update_feedback_cache
    end
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
end
