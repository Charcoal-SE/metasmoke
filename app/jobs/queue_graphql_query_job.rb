# frozen_string_literal: true

class QueueGraphqlQueryJob < ApplicationJob
  queue_as :graphql_queries

  def perform(query, **query_params)
    puts 'PERF'
    @results = MetasmokeSchema.execute(query, **query_params)
  end

  before_enqueue do
    redis.sadd 'pending_graphql_queries', job_id
  end

  before_perform do
    redis.set "graphql_queries/#{job_id}", '', ex: 600
    redis.srem 'pending_graphql_queries', job_id
  end

  after_perform do
    redis.set "graphql_queries/#{job_id}", JSON.generate(@results), ex: 300
  end
end
