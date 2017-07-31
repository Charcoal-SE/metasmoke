# frozen_string_literal: true

class Statistic < ApplicationRecord
  include Websocket

  belongs_to :smoke_detector

  after_create do
    ActionCable.server.broadcast 'api_statistics', statistic: as_json
  end
end
