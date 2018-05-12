# frozen_string_literal: true

MetasmokeSchema = GraphQL::Schema.define do
  # max_depth 5
  max_complexity (30*25)
  # mutation(Types::MutationType)
  query(Types::QueryType)
end
