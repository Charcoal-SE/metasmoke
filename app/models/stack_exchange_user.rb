class StackExchangeUser < ActiveRecord::Base
  belongs_to :site
  has_many :posts
end
