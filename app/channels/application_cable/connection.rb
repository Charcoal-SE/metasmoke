# frozen_string_literal: true

# Be sure to restart your server when you modify this file. Action Cable runs in a loop that does not support auto reloading.
module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_current_user
    end

    private

    def find_current_user
      cookies.signed['user.expires_at'] && cookies.signed['user.expires_at'] > Time.now && User.find_by(id: cookies.signed['user.id'])
    end
  end
end
