class Site < ActiveRecord::Base
  has_many :stack_exchange_users
  has_many :posts
end
