class FlagSetting < ApplicationRecord
  validates :name, :uniqueness => true

  def self.[](key)
    find_by_name(key).value
  end
end
