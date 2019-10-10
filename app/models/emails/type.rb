# frozen_string_literal: true

class Emails::Type < ApplicationRecord
  def self.[](short_name)
    find_by short_name: short_name
  end
end
