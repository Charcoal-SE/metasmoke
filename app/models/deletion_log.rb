# frozen_string_literal: true

class DeletionLog < ApplicationRecord
  include Websocket

  belongs_to :post
  belongs_to :api_key
  belongs_to :deletion_log
  validates :post_id, presence: true

  after_create do
    if is_deleted
      deletion_log = DeletionLogsController.render(
        locals: {
          deletion_log: self
        },
        partial: 'deletion_log.json'
      )
      ActionCable.server.broadcast 'api_deletion_logs', deletion_log: JSON.parse(deletion_log)
    end
  end

  after_create :update_deletion_data

  def update_deletion_data
    return unless is_deleted
    post.update(deleted_at: created_at) if post.deleted_at.nil?
    redis.hset("posts/#{post.id}", 'deleted_at', created_at.to_s)
  end

  def self.from_redis(post_id)
    del_log = new
    str = redis.hget("posts/#{post_id}", 'deleted_at')
    del_log.created_at = str
    del_log.is_deleted = !str.nil?
    [del_log]
  end

  after_create do
    DeletionLog.auto_other_flag(self, post)
  end

  def self.auto_other_flag(dl = nil, post = nil)
    return if post.nil? || !post.site&.auto_disputed_flags_enabled
    deleted = dl.present? ? dl.is_deleted : !post.deleted_at.nil?
    return unless deleted && (post.is_fp || post.is_naa) && post.flag_logs.manual.successful.count > 0

    comment_template = "Charcoal project members cast {flagtype} flags on this post, but at least one subsequent reviewer isn't confident "\
                       "that's the right decision. Please review and undelete the post if necessary; see "\
                       'https://charcoal-se.org/smokey/Auto-Mod-Flags for more details about this flag.'
    flag_type = post.flag_logs.manual.successful.map(&:flag_type).uniq.join(' & ')
    comment = comment_template.gsub('{flagtype}', flag_type)
    smokey = User.find(-1)
    status, message = smokey.other_flag(post, comment)
    FlagLog.create(
      success: status,
      error_message: status.present? ? nil : message,
      is_dry_run: false,
      user: smokey,
      post: post,
      backoff: status.present? ? message : 0,
      site_id: post.site_id,
      is_auto: true,
      flag_type: 'other',
      comment: comment
    )
  end
end
