class Feedback < ActiveRecord::Base
  belongs_to :post
  belongs_to :user
  before_save :update_post_feedback_cache

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
    return unless self.changed?

    if self.is_negative?
      post = self.post
      post.is_fp = true
      post.save! if post.changed?
    elsif self.is_positive?
      post = self.post
      post.is_tp = true
      post.save! if post.changed?
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
end
