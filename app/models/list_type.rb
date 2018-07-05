class ListType < ApplicationRecord
  has_many :list_items, dependent: :nullify
end
