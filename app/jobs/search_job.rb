# frozen_string_literal: true

require "#{Rails.root}/app/jobs/search_helpers.rb"

class SearchJob < ApplicationJob
  queue_as :searches
  include Backburner::Queue
  queue_respond_timeout SEARCH_JOB_TIMEOUT

  include SearchJobQueryBuilder

  def self.search_page_length
    SEARCH_PAGE_LENGTH
  end

  def self.search_job_timeout
    SEARCH_JOB_TIMEOUT
  end

  attr_accessor :search_id

  before_enqueue do |job|
    ops, params = job.arguments
    job_id = job.job_id
    wrapped_params = VALID_SEARCH_PARAMS.map { |k| [k, params[k]] }.to_h
    sid = redis.incr 'search_counter'
    redis.set "search_jobs/#{job_id}/sid", sid
    redis.set "search_jobs/#{job_id}/be_page", 0
    redis.set "searches/#{sid}/params", JSON.generate(wrapped_params)
    redis.rpush "searches/#{sid}/ops", ops
  end

  def perform(ops, params)
    # sid = @sid
    redis.expire "search_jobs/#{job_id}/sid", SEARCH_JOB_TIMEOUT
    redis.expire "search_jobs/#{job_id}/be_page", SEARCH_JOB_TIMEOUT
    sid = redis.get("search_jobs/#{job_id}/sid").to_i
    wrapped_params = VALID_SEARCH_PARAMS.map { |k| [k, params[k]] }.to_h
    created_at = Time.now.to_i
    redis.set "searches/#{sid}/created_at", created_at

    results = build_query(ops, wrapped_params)
    results = results.where('posts.created_at < ?', Time.at(created_at))

    counts_by_accuracy_group = results.group(:is_tp, :is_fp, :is_naa).count
    counts_by_feedback = %i[is_tp is_fp is_naa].each_with_index.map do |symbol, i|
      [symbol, counts_by_accuracy_group.select { |k, _v| k[i] }.values.sum]
    end.to_h
    redis.set "searches/#{sid}/result_count", results.count
    redis.set "searches/#{sid}/counts_by_accuracy_group", JSON.generate(counts_by_accuracy_group)
    redis.set "searches/#{sid}/counts_by_feedback", JSON.generate(counts_by_feedback)
    redis.set "searches/#{sid}/results/0", results.limit(SEARCH_PAGE_LENGTH).map(&:id).pack('I!*')
    redis.expire "searches/#{sid}/results/0", SEACH_PAGE_EXPIRATION
  end
end
