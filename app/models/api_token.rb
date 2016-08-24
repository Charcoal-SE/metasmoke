class ApiToken < ApplicationRecord
  belongs_to :api_key
  belongs_to :user

  validates :code, unique: true, length: { minimum: 7 }
  validates :token, unique: true, length: { minimum: 48 }
end
