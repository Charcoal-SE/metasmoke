# frozen_string_literal: true

Types::QueryType = GraphQL::ObjectType.define do
  name 'Query'
  # Add root-level fields here.
  # They will be entry points for queries on your schema.

  field :post do
    type Types::PostType
    argument :id, !types.ID
    description 'Find a Post by ID'
    resolve ->(_obj, args, _ctx) { Post.where(args) }
  end

  field :feedback do
    type Types::FeedbackType
    argument :id, !types.ID
    description 'Find a Feedback by ID'
    resolve ->(_obj, args, _ctx) { Feedback.where(args) }
  end

  field :smoke_detector do
    type Types::SmokeDetectorType
    argument :id, !types.ID
    description 'Find a SmokeDetector by ID'
    resolve ->(_obj, args, _ctx) { SmokeDetector.where(args) }
  end

  field :site do
    type Types::SiteType
    argument :id, !types.ID
    description 'Find a Site by ID'
    resolve ->(_obj, args, _ctx) { Site.where(args) }
  end

  field :stack_exchange_user do
    type Types::StackExchangeUserType
    argument :id, !types.ID
    description 'Find a StackExchangeUser by ID'
    resolve ->(_obj, args, _ctx) { StackExchangeUser.where(args) }
  end

  field :announcement do
    type Types::StackExchangeUserType
    argument :id, !types.ID
    description 'Find a Announcement by ID'
    resolve ->(_obj, args, _ctx) { Announcement.where(args) }
  end

  field :reason do
    type Types::ReasonType
    argument :id, !types.ID
    description 'Find a Reason by ID'
    resolve ->(_obj, args, _ctx) { Reason.where(args) }
  end

  field :user do
    type Types::UserType
    argument :id, !types.ID
    description 'Find a User by ID'
    resolve ->(_obj, args, _ctx) { User.where(args) }
  end

  # deletion_logs domain_tags flag_logs moderator_sites
end
