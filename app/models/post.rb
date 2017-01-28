class Post < ApplicationRecord
  has_and_belongs_to_many :reasons
  has_many :feedbacks, :dependent => :destroy
  has_many :deletion_logs, :dependent => :destroy
  belongs_to :site
  belongs_to :stack_exchange_user
  has_many :flag_logs

  scope :includes_for_post_row, -> { includes(:reasons).includes(:feedbacks => [:user]) }

  after_create do
    ActionCable.server.broadcast "posts_realtime", { row: PostsController.render(locals: {post: Post.last}, partial: 'post').html_safe }
  end

  after_create do
    if FlagSetting['flagging_enabled'] == '1'
      dry_run = FlagSetting['dry_run'] == '1'
      post = self
      Thread.new do
        begin
          conditions = post.site.flag_conditions.where(:flags_enabled => true)
          available_user_ids = {}
          conditions.each do |condition|
            if condition.validate!(post)
              available_user_ids[condition.user.id] = condition
            end
          end

          uids = post.site.user_site_settings.where(:user_id => available_user_ids.keys).map(&:user_id)
          users = User.where(:id => uids, :flags_enabled => true)
          successful = 0

          if users.present?
            begin
              if post.fetch_revision_count > 1
                FlagLog.create(:success => false, :error_message => "More than one revision", :is_dry_run => dry_run, :flag_condition => nil, :user => nil, :post => post)
              end
            rescue => e
              FlagLog.create(:success => false, :error_message => "Couldn't get revision count: #{e}: #{e.message} | #{e.backtrace.join("\n")}", :is_dry_run => dry_run, :flag_condition => nil, :user => nil, :post => post)
            end
          end
          if post.revision_count == 1
            users.shuffle.each do |user|
              user_site_flag_count = user.flag_logs.where(:site => post.site, :success => true, :is_dry_run => false).where(:created_at => Date.today..Time.now).count
              next if user_site_flag_count > user.user_site_settings.includes(:sites).where(:sites => { :id => post.site.id } ).last.max_flags

              last_log = FlagLog.where(:user => user).last
              if last_log.try(:backoff).present? && (last_log.created_at + last_log.backoff.seconds > Time.now)
                sleep((last_log.created_at + last_log.backoff.seconds) - Time.now)
              end

              success, message = user.spam_flag(post, dry_run)
              backoff = 0
              if success
                successful += 1
                backoff = message
              end

              FlagLog.create(:success => success, :error_message => message, :is_dry_run => dry_run, :flag_condition => available_user_ids[user.id], :user => user, :post => post, :backoff => backoff)

              if successful >= [post.site.max_flags_per_post, (FlagSetting['max_flags'] || '3').to_i].min
                break
              end
            end
          end
        rescue => e
          FlagLog.create(:success => false, :error_message => "#{e}: #{e.message} | #{e.backtrace.join("\n")}", :is_dry_run => dry_run, :flag_condition => nil, :post => post)
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
      SmokeDetector.send_message_to_charcoal "Conflicting feedback on [#{self.title}](//metasmoke.erwaysoftware.com/post/#{self.id})."
    end

    if self.is_fp_changed? && self.is_fp && self.flagged?
      SmokeDetector.send_message_to_charcoal "**fp on autoflagged post**: #{self.title}](//metasmoke.erwaysoftware.com/post/#{self.id})"
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

  def flagged?
    self.flag_logs.where(:success => true).present?
  end

  def fetch_revision_count
    params = "key=#{AppConfig["stack_exchange"]["key"]}&site=#{site.site_domain}&filter=!mggE4ZSiE7"

    url = "https://api.stackexchange.com/posts/#{stack_id}/revisions?#{params}"
    revision_list = JSON.parse(Net::HTTP.get_response(URI.parse(url)).body)["items"]

    update(:revision_count => revision_list.count)
    revision_list.count
  end
end
