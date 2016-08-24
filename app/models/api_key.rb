class ApiKey < ApplicationRecord
  validates :key, length: { minimum: 10, maximum: 100 }
  validates_uniqueness_of :key

  validates :app_name, length: { minimum: 1 }, unique: true

  has_many :feedbacks
end
