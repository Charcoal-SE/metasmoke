# frozen_string_literal: true

class FlagSetting < ApplicationRecord
  include Websocket

  audited
  validates :name, uniqueness: true

  def self.[](key)
    find_by(name: key).try(:value)
  end
end
