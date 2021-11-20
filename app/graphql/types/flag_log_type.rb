# frozen_string_literal: true

Types::FlagLogType = GraphQL::ObjectType.define do
  name 'FlagLog'
  field :success, types.Boolean
  field :error_message, types.String
  field :is_dry_run, types.Boolean
  field :backoff, types.Int
  field :is_auto, types.Boolean
  field :user, Types::UserType do
    complexity lambda { |_ctx, _args, child_complexity|
      (BASE * 25) + (child_complexity > 1 ? child_complexity : 1)
    }
  end
  field :post, Types::PostType do
    complexity lambda { |_ctx, _args, child_complexity|
      (BASE * 25) + (child_complexity > 1 ? child_complexity : 1)
    }
  end
  field :site, Types::SiteType do
    complexity lambda { |_ctx, _args, child_complexity|
      (BASE * 25) + (child_complexity > 1 ? child_complexity : 1)
    }
  end
  field :flag_condition, Types::FlagConditionType do
    complexity lambda { |_ctx, _args, child_complexity|
      (BASE * 25) + (child_complexity > 1 ? child_complexity : 1)
    }
  end

  field :created_at, Types::DateTimeType
  field :updated_at, Types::DateTimeType
  field :id, types.ID
end
