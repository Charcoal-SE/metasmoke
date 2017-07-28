# frozen_string_literal: true

class ModeratorSite < ApplicationRecord
  include Websocket

  belongs_to :site
  belongs_to :user
end
