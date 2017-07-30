# frozen_string_literal: true

class Flag < ApplicationRecord
  include Websocket

  belongs_to :post
end
