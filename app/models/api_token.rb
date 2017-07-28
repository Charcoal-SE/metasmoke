# frozen_string_literal: true

class APIToken < ApplicationRecord
  include WebSocket

  belongs_to :api_key
  belongs_to :user

  validates :code, uniqueness: true, length: { minimum: 7 }
  validates :token, uniqueness: true, length: { minimum: 48 }
end
