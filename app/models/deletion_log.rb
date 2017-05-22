# frozen_string_literal: true

class DeletionLog < ApplicationRecord
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
end
