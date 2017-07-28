# frozen_string_literal: true

class Statistic < ApplicationRecord
  include WebSocket

  belongs_to :smoke_detector
end
