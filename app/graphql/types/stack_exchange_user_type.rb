# frozen_string_literal: true

Types::StackExchangeUserType = GraphQL::ObjectType.define do
  name 'StackExchangeUser'
  field :user_id, types.Int
  field :username, types.String
  field :last_api_update, Types::DateTimeType
  field :still_alive, types.Boolean
  field :answer_count, types.Int
  field :question_count, types.Int
  field :reputation, types.Int
  field :site, types[Types::SiteType]
  field :posts, types[Types::PostType]

  field :created_at, Types::DateTimeType
  field :updated_at, Types::DateTimeType
  field :id, types.Int
end
