# frozen_string_literal: true

Types::SmokeDetectorType = GraphQL::ObjectType.define do
  name 'SmokeDetector'
  field :last_ping, Types::DateTimeType
  field :name, types.String
  field :location, types.String
  field :is_standby, types.Boolean
  field :force_failover, types.Boolean
  field :user, Types::UserType

  field :created_at, Types::DateTimeType
  field :updated_at, Types::DateTimeType
  field :id, types.ID
end
