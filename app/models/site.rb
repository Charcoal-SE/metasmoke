class Site < ApplicationRecord
  has_many :stack_exchange_users
  has_many :posts
  has_and_belongs_to_many :users
  has_many :user_site_settings
  has_and_belongs_to_many :flag_conditions
end
