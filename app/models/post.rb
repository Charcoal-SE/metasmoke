class Post < ApplicationRecord
  has_and_belongs_to_many :reasons
  has_many :feedbacks, :dependent => :destroy
  has_many :deletion_logs, :dependent => :destroy
  belongs_to :site
  belongs_to :stack_exchange_user
  has_many :flag_logs

  after_create do
    ActionCable.server.broadcast "posts_realtime", { row: PostsController.render(locals: {post: Post.last}, partial: 'post').html_safe }
  end

  after_save do
    if FlagSetting['flagging_enabled'] == '1'
      post = self
      Thread.new do
        conditions = post.site.flag_conditions
        available_user_ids = []
        conditions.each do |condition|
          if condition.validate!(post)
            available_user_ids << condition.user.id
          end
        end

        users = UserSiteSetting.where(:user_id => available_user_ids, :site_id => @post.site.id).where('flags_used < max_flags').pluck(:user)
        successful = 0
        users.each do |user|
          success, message = user.spam_flag(post, FlagSetting['dry_run'] == '1')
          if success
            successful += 1
          end

          FlagLog.create(:success => success, :message => message)

          if successful >= [@post.site.max_flags_per_post, FlagSetting['max_flags'].to_i].min
            break
          end
        end
      end
    end
  end

  def update_feedback_cache
    self.is_tp = false
    self.is_fp = false

    feedbacks = self.feedbacks.to_a

    self.is_tp = true if feedbacks.index { |f| f.is_positive? }
    self.is_fp = true if feedbacks.index { |f| f.is_negative? }
    self.is_naa = true if feedbacks.index { |f| f.is_naa? }

    is_feedback_changed = self.is_tp_changed? || self.is_fp_changed? || self.is_naa_changed?

    save!

    if self.is_tp && self.is_fp
      ActionCable.server.broadcast "smokedetector_messages", { message: "Conflicting feedback on [#{self.title}](//metasmoke.erwaysoftware.com/post/#{self.id})." }
    end

    return is_feedback_changed
  end

  def is_question?
    return self.link.include? "/questions/"
  end

  def is_answer?
    return self.link.include? "/a/"
  end

  def stack_id
    return self.link.scan(/(\d*)$/).first.first.to_i
  end
end
