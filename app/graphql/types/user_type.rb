# frozen_string_literal: true

Types::UserType = GraphQL::ObjectType.define do
  name 'User'
  field :username, types.String
  field :stackexchange_chat_id, types.Int
  field :meta_stackexchange_chat_id, types.Int
  field :stackoverflow_chat_id, types.Int
  field :stack_exchange_account_id, types.Int
  field :feedbacks, types[Types::FeedbackType] do
    complexity ->(_ctx, _args, child_complexity) do
      (BASE * 25) + (child_complexity > 1 ? child_complexity : 1)
    end
  end
  field :post_comments, types[Types::PostCommentType] do
    complexity ->(_ctx, _args, child_complexity) do
      (BASE * 25) + (child_complexity > 1 ? child_complexity : 1)
    end
  end
  field :smoke_detectors, types[Types::SmokeDetectorType] do
    complexity ->(_ctx, _args, child_complexity) do
      (BASE * 25) + (child_complexity > 1 ? child_complexity : 1)
    end
  end
  field :flag_logs, types[Types::FlagLogType] do
    complexity ->(_ctx, _args, child_complexity) do
      (BASE * 25) + (child_complexity > 1 ? child_complexity : 1)
    end
  end

  field :id, types.ID
end
