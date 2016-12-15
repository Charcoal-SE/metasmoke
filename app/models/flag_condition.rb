class FlagCondition < ApplicationRecord
  belongs_to :user
  has_and_belongs_to_many :sites
  has_many :flag_logs, :dependent => :destroy

  validates :min_weight, :numericality => { :greater_than_or_equal_to => 294 }
  validates :max_poster_rep, :inclusion => { :in => 0..50 }
  validates :min_reason_count, :inclusion => { :in => 3..25 }
end
