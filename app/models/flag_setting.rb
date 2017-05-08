class FlagSetting < ApplicationRecord
  audited
  validates :name, uniqueness: true

  def self.[](key)
    find_by_name(key).try(:value)
  end
end
