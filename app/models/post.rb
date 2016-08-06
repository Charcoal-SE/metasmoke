class Post < ApplicationRecord
  has_and_belongs_to_many :reasons
  has_many :feedbacks
  has_many :deletion_logs
  belongs_to :site
  belongs_to :stack_exchange_user

  after_create do
    ActionCable.server.broadcast "posts_realtime", { row: PostsController.render(locals: {post: Post.last}, partial: 'post').html_safe }
  end

  def update_feedback_cache
    self.is_tp = false
    self.is_fp = false

    feedbacks = self.feedbacks.to_a

    self.is_tp = true if feedbacks.index { |f| f.is_positive? }
    self.is_fp = true if feedbacks.index { |f| f.is_negative? }

    is_feedback_changed = self.is_tp_changed? || self.is_fp_changed?

    save!

    if self.is_tp and self.is_fp
      ActionCable.server.broadcast "smokedetector_messages", { message: "Conflicting feedback on [#{self.title}](//metasmoke.erwaysoftware.com/post/#{self.id})." }
    end

    return is_feedback_changed
  end
end
