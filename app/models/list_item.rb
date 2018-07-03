class ListItem < ApplicationRecord
  belongs_to :list_type
  belongs_to :user
end
