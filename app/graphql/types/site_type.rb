Types::SiteType = GraphQL::ObjectType.define do
  name "Site"
  field :site_name, types.String
  field :site_url, types.String
  field :site_logo, types.String
  field :site_domain, types.String
  field :flags_enabled, types.Boolean
  field :max_flags_per_post, types.Int
  field :is_child_meta, types.Boolean
  field :last_users_update, Types::DateTimeType

  field :created_at, Types::DateTimeType
  field :updated_at, Types::DateTimeType
  field :id, types.Int
end
