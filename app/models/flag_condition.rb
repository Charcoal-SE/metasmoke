class FlagCondition < ApplicationRecord
  belongs_to :user
  has_and_belongs_to_many :sites
  has_many :flag_logs, :dependent => :destroy

  validates :min_weight, :numericality => { :greater_than_or_equal_to => 294 }
  validates :max_poster_rep, :numericality => { :greater_than_or_equal_to => 0, :less_than_or_equal_to => 50 }
  validates :min_reason_count, :numericality => { :greater_than_or_equal_to => 3, :less_than_or_equal_to => 25 }
end
