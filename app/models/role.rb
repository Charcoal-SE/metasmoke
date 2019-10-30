# frozen_string_literal: true

class Role < ApplicationRecord
  include Websocket

  has_and_belongs_to_many :users, join_table: :users_roles

  belongs_to :resource,
             polymorphic: true,
             optional: true

  validates :resource_type,
            inclusion: { in: Rolify.resource_types },
            allow_nil: true

  scopify

  def self.names
    %i[reviewer flagger core smoke_detector_runner blacklist_manager admin developer]
  end
end
