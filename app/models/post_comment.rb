# frozen_string_literal: true

class PostComment < ApplicationRecord
  include Websocket

  belongs_to :post
  belongs_to :user
end
