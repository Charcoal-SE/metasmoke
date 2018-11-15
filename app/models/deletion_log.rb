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

  after_create do
    post.update(deleted_at: created_at) if is_deleted && post.deleted_at.nil?
  end

  after_create do
    DeletionLog.auto_other_flag(self, post)
  end

  def self.auto_other_flag(dl = nil, post = nil)
    return if post.nil?
    deleted = dl.present? ? dl.is_deleted : !post.deleted_at.nil?
    if deleted && (post.is_fp || post.is_naa)
      comment_template = "This post had {flags} spam flag(s) cast on it by Charcoal members and has since been deleted, but was ultimately judged "\
                         "not to have been spam. Please review whether spam flags - and the penalty that comes with them - are appropriate for this "\
                         "post - you can let us know in https://chat.stackexchange.com/rooms/11540 if the flags were inappropriate. "\
                         "If you're wondering WTF this flag is, see https://charcoal-se.org/smokey/Auto-Mod-Flags for details."
      comment = comment_template.gsub('{flags}', post.flag_logs.manual.successful.count)
      User.find(-1).other_flag(post, comment)
    end
  end
end
