# frozen_string_literal: true

class Statistic < ApplicationRecord
  include Websocket

  belongs_to :smoke_detector
end
