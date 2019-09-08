# frozen_string_literal: true

Types::DomainTagType = GraphQL::ObjectType.define do
  name 'DomainTag'
  field :description, types.String
  field :name, types.String
  field :special, types.Boolean
  field :posts, types[Types::PostType]
  field :spam_domains, types[Types::SpamDomainType]

  field :created_at, Types::DateTimeType
  field :updated_at, Types::DateTimeType
  field :id, types.ID
end
