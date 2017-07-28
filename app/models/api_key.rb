# frozen_string_literal: true

class APIKey < ApplicationRecord
  validates :key, length: { minimum: 10, maximum: 100 }
  validates :key, uniqueness: true

  validates :app_name, length: { minimum: 1 }, uniqueness: true

  has_many :feedbacks
  has_many :api_tokens
  has_many :deletion_logs
  has_many :flag_logs

  # APIKey.user is the *owner* of the API application that the key belongs to.
  belongs_to :user
end
