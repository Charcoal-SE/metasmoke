# frozen_string_literal: true

Types::PostType = GraphQL::ObjectType.define do
  name 'Post'
  field :title, types.String
  field :body, types.String
  field :link, types.String
  field :post_creation_date, Types::DateTimeType
  field :site, Types::SiteType
  field :user_link, types.String
  field :username, types.String
  field :why, types.String
  field :user_reputation, types.Int
  field :upvote_count, types.Int
  field :downvote_count, types.Int
  field :score, types.Int
  field :feedbacks, types[Types::FeedbackType]
  field :stack_exchange_user, Types::StackExchangeUserType
  field :is_tp, types.Boolean
  field :is_fp, types.Boolean
  field :is_naa, types.Boolean
  field :revision_count, types.Int
  field :deleted_at, Types::DateTimeType
  field :smoke_detector, Types::SmokeDetectorType
  field :autoflagged, types.Boolean
  field :tags, types.String
  field :feedbacks_count, types.Int
  field :native_id, types.Int
  field :reasons, types[Types::ReasonType]
  field :spam_domains, types[Types::SpamDomainType]
  field :flag_logs, types[Types::FlagLogType]
  field :comments, types[Types::PostCommentType]
  field :post_tags, types[Types::DomainTagType]

  field :created_at, Types::DateTimeType
  field :updated_at, Types::DateTimeType
  field :id, types.ID
end
