# frozen_string_literal: true

class AbuseReportStatus < ApplicationRecord
  has_many :reports, class_name: 'AbuseReport', dependent: :nullify

  DEFAULT_STATUS = 'Open'

  def self.[](key)
    find_by name: key
  end
end
