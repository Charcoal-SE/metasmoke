# frozen_string_literal: true

Types::FeedbackType = GraphQL::ObjectType.define do
  name 'Feedback'
  field :message_link, types.String
  field :user_name, types.String
  field :user_link, types.String
  field :feedback_type, types.String
  field :post, Types::PostType
  field :user, Types::UserType
  field :chat_user_id, types.Int
  field :chat_host, types.String

  field :created_at, Types::DateTimeType
  field :updated_at, Types::DateTimeType
  field :id, types.ID
end
