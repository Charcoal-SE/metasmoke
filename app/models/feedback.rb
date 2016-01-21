class Feedback < ActiveRecord::Base
  belongs_to :post

  def is_positive?
    self.feedback_type.include? "t"
  end
  def is_negative?
    self.feedback_type.include? "f"
  end
end
