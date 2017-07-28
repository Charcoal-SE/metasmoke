# frozen_string_literal: true

class ModeratorSite < ApplicationRecord
  include WebSocket

  belongs_to :site
  belongs_to :user
end
