class Lists::Item < ApplicationRecord
  belongs_to :user
  belongs_to :list, class_name: 'Lists::List', foreign_key: 'lists_list_id'
end
