require "#{Rails.root}/app/jobs/search_helpers.rb"

class SearchExtendJob < ApplicationJob
  queue_as :searches
  include Backburner::Queue
  queue_respond_timeout SEARCH_JOB_TIMEOUT

  include SearchJobQueryBuilder

  before_enqueue do |job|
    sid, be_page = job.arguments
    job_id = job.job_id
    redis.set "search_jobs/#{job_id}/sid", sid
    redis.set "search_jobs/#{job_id}/be_page", be_page
  end

  def perform(sid, be_page)
    redis.expire "search_jobs/#{job_id}/sid", SEARCH_JOB_TIMEOUT
    redis.expire "search_jobs/#{job_id}/be_page", SEARCH_JOB_TIMEOUT
    wrapped_params = JSON.parse(redis.get("searches/#{sid}/params")).symbolize_keys
    ops = redis.lrange "searches/#{sid}/ops", 0, -1
    created_at = redis.get "searches/#{sid}/created_at"
    query = build_query(ops, wrapped_params)
    query = query.where('posts.created_at < ?', Time.at(created_at.to_i))
    redis.set "searches/#{sid}/results/#{be_page}", query.offset(SEARCH_PAGE_LENGTH * be_page).limit(SEARCH_PAGE_LENGTH).select(:id).map(&:id).pack("I!*")
    redis.expire "searches/#{sid}/results/0", SEACH_PAGE_EXPIRATION
  end

  after_perform do |job|
    sid, be_page = job.arguments
    redis.del "searches/#{sid}/results/#{be_page}/job_id"
  end
end
