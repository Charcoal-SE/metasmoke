# frozen_string_literal: true

Types::PostCommentType = GraphQL::ObjectType.define do
  name 'PostComment'
  field :text, types.String
  field :user, Types::UserType
  field :post, Types::PostType

  field :created_at, Types::DateTimeType
  field :updated_at, Types::DateTimeType
  field :id, types.Int
end
