class Announcement < ApplicationRecord
  def self.current
    Announcement.where('expiry > ?', DateTime.now)
  end
end
