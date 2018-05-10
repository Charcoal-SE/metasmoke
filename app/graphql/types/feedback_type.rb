Types::FeedbackType = GraphQL::ObjectType.define do
  name "Feedback"
  field :message_link, types.String
  field :user_name, types.String
  field :user_link, types.String
  field :feedback_type, types.String
  field :post, Types::PostType

  field :created_at, Types::DateTimeType
  field :updated_at, Types::DateTimeType
  field :id, types.Int
end
