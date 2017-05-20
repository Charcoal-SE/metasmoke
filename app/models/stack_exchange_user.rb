class StackExchangeUser < ApplicationRecord
  belongs_to :site
  has_many :posts
  has_many :feedbacks, through: :posts

  def stack_link
    "#{site.site_url}/users/#{user_id}"
  end

  def flair_link
    "#{site.site_url}/users/flair/#{user_id}.png"
  end
end
