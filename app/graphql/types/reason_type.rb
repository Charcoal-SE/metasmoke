# frozen_string_literal: true

Types::ReasonType = GraphQL::ObjectType.define do
  name 'Reason'
  field :reason_name, types.String
  field :last_post_title, types.String
  field :inactive, types.Boolean
  field :weight, types.Int
  field :maximum_weight, types.Int
  field :posts, types[Types::PostType]

  field :id, types.ID
end
