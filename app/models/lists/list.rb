class Lists::List < ApplicationRecord
  validates :name, presence: true
  validates :write_privs, inclusion: Role.names.map(&:to_s)
  validates :manage_privs, inclusion: Role.names.map(&:to_s)

  has_many :items, class_name: 'Lists::Item', foreign_key: 'lists_list_id'
end
