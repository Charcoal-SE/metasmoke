class Lists::List < ApplicationRecord
  validates :name, presence: true
  validates :write_privs, inclusion: Role.names.map(&:to_s)
  validates :manage_privs, inclusion: Role.names.map(&:to_s)
end
