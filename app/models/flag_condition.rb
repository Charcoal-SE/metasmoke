class FlagCondition < ApplicationRecord
  belongs_to :user
  has_and_belongs_to_many :sites
  has_many :flag_logs
end
