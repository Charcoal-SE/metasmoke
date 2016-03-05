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
end
