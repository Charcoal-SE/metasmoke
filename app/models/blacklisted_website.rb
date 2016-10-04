class BlacklistedWebsite < ApplicationRecord
  validates :host, length: {minimum: 1}

  def self.active
    self.where(:is_active => true)
  end

  def self.inactive
    self.where(:is_active => false)
  end
end
