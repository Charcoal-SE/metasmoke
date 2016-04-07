class Site < ApplicationRecord
  has_many :stack_exchange_users
  has_many :posts
end
