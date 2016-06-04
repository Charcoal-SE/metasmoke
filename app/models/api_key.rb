class ApiKey < ApplicationRecord
  validates :key, length: { minimum: 10, maximum: 100 }
  validates_uniqueness_of :key
end
