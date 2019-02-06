# frozen_string_literal: true

MetasmokeSchema = GraphQL::Schema.define do
  max_depth 6
  max_complexity 5000
  # mutation(Types::MutationType)
  query(Types::QueryType)
end
