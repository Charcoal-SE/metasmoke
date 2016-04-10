class Post < ApplicationRecord
  has_and_belongs_to_many :reasons
  has_many :feedbacks
  belongs_to :site
  belongs_to :stack_exchange_user

  def update_feedback_cache
    self.is_tp = false
    self.is_fp = false

    feedbacks = self.feedbacks.to_a

    self.is_tp = true if feedbacks.index { |f| f.is_positive? }
    self.is_fp = true if feedbacks.index { |f| f.is_negative? }

    save!
  end
end
