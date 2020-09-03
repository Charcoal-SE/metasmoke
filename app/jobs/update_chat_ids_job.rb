# frozen_string_literal: true

class UpdateChatIdsJob < ApplicationJob
  queue_as :default

  def perform(user_id)
    u = User.find(user_id)
    u.update_chat_ids
    u.save!
  end
end
