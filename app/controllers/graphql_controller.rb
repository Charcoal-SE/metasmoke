# frozen_string_literal: true

class GraphqlController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:execute]

  def execute
    variables = ensure_hash(params[:variables])
    query = params[:query]
    operation_name = params[:operationName]
    context = {
      # Query context goes here, for example:
      # current_user: current_user
    }
    query_params = { variables: variables, context: context, operation_name: operation_name }
    if user_signed_in? && current_user.has_role?(:core)
      # query_params.merge!({max_depth: 8, max_complexity:20})
    end

    api_key = APIKey.find_by(key: params[:key])
    if (user_signed_in? && current_user.has_role?(:core)) || (!api_key.nil? && api_key.api_tokens.exists?(token: params[:token]))
      @results = MetasmokeSchema.execute(query, **query_params)
      respond_to do |format|
        format.json { render json: @results }
        format.html { @results = JSON.pretty_generate(@results.to_hash) }
      end
    elsif user_signed_in? || !api_key.nil?
      @job_id = QueueGraphqlQueryJob.perform_later(query, **query_params).job_id
      respond_to do |format|
        format.json { render json: {job_id: @job_id} }
        format.html { redirect_to view_graphql_job_path(job_id: @job_id) }
      end
    else
      return head :forbidden
    end
  end

  def view_job
    k = "graphql_queries/#{params[:job_id]}"
    if redis.sismember "pending_graphql_queries", params[:job_id]
      respond_to do |format|
        format.json { render json: {complete: false, pending: true} }
        format.html { render action: :pending_job }
      end
    elsif redis.exists k
      v = redis.get k
      time_remaining = redis.ttl(k).to_i
      @time_elapsed = 600 - time_remaining
      if v == ""
        respond_to do |format|
          format.json { render json: {complete: false, time_elapsed: @time_elapsed} }
          format.html { render action: :pending_job }
        end
      else
        @results = JSON.parse(v)
        respond_to do |format|
          format.json { render json: @results }
          format.html { @results = JSON.pretty_generate(@results.to_hash); render action: :execute }
        end
      end
    else
      return head 404
    end
  end

  def query; end

  private

  # def valid_api_token
  #   key = APIKey.find_by(key: params[:key])
  #   !key.nil? && key.api_tokens.exists?(token: params[:token])
  # end

  # Handle form data, JSON body, or a blank value
  def ensure_hash(ambiguous_param)
    case ambiguous_param
    when String
      if ambiguous_param.present?
        ensure_hash(JSON.parse(ambiguous_param))
      else
        {}
      end
    when Hash, ActionController::Parameters
      ambiguous_param
    when nil
      {}
    else
      raise ArgumentError, "Unexpected parameter: #{ambiguous_param}"
    end
  end
end
