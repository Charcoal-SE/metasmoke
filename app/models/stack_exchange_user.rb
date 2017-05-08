class StackExchangeUser < ApplicationRecord
  belongs_to :site
  has_many :posts
  has_many :feedbacks, through: :posts

  def stack_link
    return "#{self.site.site_url}/users/#{self.user_id}"
  end

  def flair_link
    return "#{self.site.site_url}/users/flair/#{self.user_id}.png"
  end
end
