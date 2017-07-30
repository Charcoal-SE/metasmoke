# frozen_string_literal: true

class IgnoredUser < ApplicationRecord
  include Websocket

  belongs_to :user
end
