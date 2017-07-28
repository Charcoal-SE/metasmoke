# frozen_string_literal: true

class Role < ApplicationRecord
  include WebSocket

  has_and_belongs_to_many :users, join_table: :users_roles

  belongs_to :resource,
             polymorphic: true,
             optional: true

  validates :resource_type,
            inclusion: { in: Rolify.resource_types },
            allow_nil: true

  scopify

  def self.names
    [:reviewer, :flagger, :core, :smoke_detector_runner, :code_admin, :admin, :developer]
  end
end
