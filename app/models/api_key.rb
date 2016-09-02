class ApiKey < ApplicationRecord
  validates :key, length: { minimum: 10, maximum: 100 }
  validates_uniqueness_of :key

  validates :app_name, length: { minimum: 1 }, uniqueness: true

  has_many :feedbacks
  has_many :api_tokens

  # ApiKey.user is the *owner* of the API application that the key belongs to.
  belongs_to :user
end
