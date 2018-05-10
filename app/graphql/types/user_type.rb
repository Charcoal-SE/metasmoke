# frozen_string_literal: true

Types::UserType = GraphQL::ObjectType.define do
  name 'User'
  field :username, types.String
  field :stackexchange_chat_id, types.Int
  field :meta_stackexchange_chat_id, types.Int
  field :stackoverflow_chat_id, types.Int
  field :stack_exchange_account_id, types.Int
  field :feedbacks, types[Types::FeedbackType]
  field :post_comments, types[Types::PostCommentType]
  field :smoke_detectors, types[Types::SmokeDetectorType]

  field :id, types.ID
end
