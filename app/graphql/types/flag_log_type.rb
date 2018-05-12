# frozen_string_literal: true

Types::FlagLogType = GraphQL::ObjectType.define do
  name 'FlagLog'
  field :success, types.Boolean
  field :error_message, types.String
  field :is_dry_run, types.Boolean
  field :backoff, types.Int
  field :is_auto, types.Boolean
  field :user, Types::UserType
  field :post, Types::PostType
  field :site, Types::SiteType
  field :flag_condition, Types::FlagConditionType

  field :created_at, Types::DateTimeType
  field :updated_at, Types::DateTimeType
  field :id, types.ID
end
