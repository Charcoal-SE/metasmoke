# frozen_string_literal: true

class StatusChannel < ApplicationCable::Channel
  def subscribed
    if current_user&.has_role?(:blacklist_manager)
      stream_from 'status_code_admin'
    else
      stream_from 'status'
    end
  end
end
