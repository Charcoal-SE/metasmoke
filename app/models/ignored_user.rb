# frozen_string_literal: true

class IgnoredUser < ApplicationRecord
  include WebSocket

  belongs_to :user
end
