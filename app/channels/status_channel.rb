# frozen_string_literal: true

class StatusChannel < ApplicationCable::Channel
  def subscribed
    if current_user&.has_role?(:blacklist_manager)
      stream_from 'status_blacklist_manager'
    else
      stream_from 'status'
    end
  end
end
