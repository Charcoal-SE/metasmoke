class UserSiteSetting < ApplicationRecord
  belongs_to :user
  belongs_to :site
end
