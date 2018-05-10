# frozen_string_literal: true

Types::SpamDomainType = GraphQL::ObjectType.define do
  name 'SpamDomain'
  field :domain, types.String
  field :whois, types.String
  field :posts, types[Types::PostType]

  field :created_at, Types::DateTimeType
  field :updated_at, Types::DateTimeType
  field :id, types.Int
end
