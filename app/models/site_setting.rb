# frozen_string_literal: true

class SiteSetting < ApplicationRecord
  validates :name, uniqueness: true

  after_save :populate_redis

  def populate_redis
    redis.set "site_setting/#{name}", value
  end

  after_destroy :remove_from_redis

  def remove_from_redis(ss)
    redis.del "site_setting/#{ss.name}"
  end

  def self.[](key)
    inst = find_by name: key
    case inst&.value_type
    when 'boolean'
      inst&.value&.to_i == 1
    when 'number'
      inst&.value&.to_i
    when 'float'
      inst&.value&.to_f
    else
      inst&.value
    end
  end

  def self.[]=(key, val)
    inst = find_by name: key
    db_val = case inst&.value_type
             when 'boolean'
               val == 'true' ? 1 : 0
             when 'number'
               val.to_s
             when 'float'
               val.to_s
             else
               val
             end
    inst&.update(value: db_val)
  end
end
