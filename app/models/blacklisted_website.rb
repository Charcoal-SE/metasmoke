class BlacklistedWebsite < ApplicationRecord
  validates :host, length: {minimum: 1}
end
