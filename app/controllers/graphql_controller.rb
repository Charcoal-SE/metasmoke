# frozen_string_literal: true

class GraphqlController < ApplicationController
  def execute
    variables = ensure_hash(params[:variables])
    query = params[:query]
    operation_name = params[:operationName]
    context = {
      # Query context goes here, for example:
      current_user: current_user
    }
    query_params = {variables: variables, context: context, operation_name: operation_name}
    if user_signed_in? && current_user.has_role?(:core)
      # query_params.merge!({max_depth: 8, max_complexity:20})
    end
    @results = MetasmokeSchema.execute(query, **query_params)
    respond_to do |format|
      format.json { render json: @results }
      format.html { @results = JSON.pretty_generate(@results.to_hash) }
    end
  end

  def query; end

  private

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
