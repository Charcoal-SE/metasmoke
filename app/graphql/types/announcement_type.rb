# frozen_string_literal: true

Types::AnnouncementType = GraphQL::ObjectType.define do
  name 'Announcement'
  field :text, types.String
  field :expiry, Types::DateTimeType

  field :created_at, Types::DateTimeType
  field :updated_at, Types::DateTimeType
end
