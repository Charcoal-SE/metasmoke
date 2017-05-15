class Statistic < ApplicationRecord
  belongs_to :smoke_detector

  after_create do
    ActionCable.server.broadcast "api_statistics", {statistic: self.as_json}
  end
end
