class StackExchangeUser < ApplicationRecord
  belongs_to :site
  has_many :posts
  has_many :feedbacks, :through => :posts
end
