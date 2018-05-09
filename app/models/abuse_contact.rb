# frozen_string_literal: true

class AbuseContact < ApplicationRecord
  has_many :reports, class_name: 'AbuseReport', dependent: :nullify
end
