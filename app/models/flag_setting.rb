class FlagSetting < ApplicationRecord
  def self.[](key)
    find_by_name(key).value
  end
end
