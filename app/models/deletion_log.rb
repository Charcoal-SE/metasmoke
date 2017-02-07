class DeletionLog < ApplicationRecord
  belongs_to :post
  validates :post_id, presence: true

  after_create do
    if is_deleted
      ActionCable.server.broadcast "api_deletion_logs", { deletion_log: JSON.parse(DeletionLogsController.render(locals: {deletion_log: self}, partial: 'deletion_log.json')) }
    end
  end
end
