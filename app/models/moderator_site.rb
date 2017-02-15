class ModeratorSite < ApplicationRecord
  belongs_to :site
  belongs_to :user
end
