# frozen_string_literal: true

class Flag < ApplicationRecord
  include WebSocket

  belongs_to :post
end
