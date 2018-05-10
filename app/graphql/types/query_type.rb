Types::QueryType = GraphQL::ObjectType.define do
  name "Query"
  # Add root-level fields here.
  # They will be entry points for queries on your schema.

  # TODO: remove me
  field :testField, types.String do
    description "An example field added by the generator"
    resolve ->(obj, args, ctx) {
      "Hello World!"
    }
  end

  field :post do
    type Types::PostType
    argument :id, !types.ID
    description "Find a Post by ID"
    resolve ->(obj, args, ctx) { Post.find(args["id"]) }
  end

  field :feedback do
    type Types::FeedbackType
    argument :id, !types.ID
    description "Find a Feedback by ID"
    resolve ->(obj, args, ctx) { Feedback.find(args["id"]) }
  end

  field :smoke_detector do
    type Types::SmokeDetectorType
    argument :id, !types.ID
    description "Find a SmokeDetector by ID"
    resolve ->(obj, args, ctx) { SmokeDetector.find(args["id"]) }
  end

  field :site do
    type Types::SiteType
    argument :id, !types.ID
    description "Find a Site by ID"
    resolve ->(obj, args, ctx) { Site.find(args["id"]) }
  end

  field :stack_exchange_user do
    type Types::StackExchangeUserType
    argument :id, !types.ID
    description "Find a StackExchangeUser by ID"
    resolve ->(obj, args, ctx) { StackExchangeUser.find(args["id"]) }
  end

  field :announcement do
    type Types::StackExchangeUserType
    argument :id, !types.ID
    description "Find a Announcement by ID"
    resolve ->(obj, args, ctx) { Announcement.find(args["id"]) }
  end

  field :reason do
    type Types::ReasonType
    argument :id, !types.ID
    description "Find a Reason by ID"
    resolve ->(obj, args, ctx) { Reason.find(args["id"]) }
  end

  # deletion_logs domain_tags flag_logs moderator_sites
end
