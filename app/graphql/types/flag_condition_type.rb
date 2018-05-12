Types::FlagConditionType = GraphQL::ObjectType.define do
  name "FlagCondition"
  field :flags_enabled, types.Boolean
  field :min_weight, types.Int
  field :max_poster_rep, types.Int
  field :min_reason_count, types.Int
  field :user, Types::UserType
  field :sites, types[Types::SiteType]

  field :created_at, Types::DateTimeType
  field :updated_at, Types::DateTimeType
  field :id, types.ID
end
