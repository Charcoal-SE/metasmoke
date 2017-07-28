# frozen_string_literal: true

class DeletionLog < ApplicationRecord
  include WebSocket

  belongs_to :post
  belongs_to :api_key
  belongs_to :deletion_log
  validates :post_id, presence: true

  after_create do
    post.update(deleted_at: created_at) if is_deleted && post.deleted_at.nil?
  end
end
