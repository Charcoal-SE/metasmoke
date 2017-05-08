class DeletionLog < ApplicationRecord
  belongs_to :post
  belongs_to :api_key
  belongs_to :deletion_log
  validates :post_id, presence: true

  after_create do
    if is_deleted
      ActionCable.server.broadcast 'api_deletion_logs', { deletion_log: JSON.parse(DeletionLogsController.render(locals: {deletion_log: self}, partial: 'deletion_log.json')) }
    end
  end

  after_create do
    if is_deleted and post.deleted_at.nil?
      post.update(deleted_at: created_at)
    end
  end
end
