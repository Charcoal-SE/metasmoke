class ListItem < ApplicationRecord
  belongs_to :list_type, required: false
  belongs_to :user, required: false
  belongs_to :smoke_detector, required: false

  serialize :data, JSON
end
