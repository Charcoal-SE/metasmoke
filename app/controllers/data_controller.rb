# frozen_string_literal: true

class DataController < ApplicationController
  before_action :verify_core

  def index; end

  def retrieve
    types = data_params[:types].to_a
    limits = data_params[:limits].to_h
    limits = limits.map do |k, v|
      begin
        [k, v.to_i]
      rescue
        render status: :bad_request
        return # rubocop:disable Lint/NonLocalExitFromIterator
      end
    end.to_h

    # This means this route will be slow-ish in dev, but should speed up in prod
    Rails.application.eager_load! unless Rails.application.config.cache_classes

    tables = types.map do |t|
      clazz = t.classify
      next unless Object.const_defined? clazz
      const = clazz.constantize
      if const < ApplicationRecord
        [t, const, (limits.include?(t) ? limits[t] : 100)]
      end
    end

    data = tables.map { |v| [v[0], v[1].order(id: :desc).limit(v[2]).select(public_fields(v[0], v[1]))] }.to_h
    render json: data
  end

  def table_schema
    table = params[:table]
    if table.blank?
      render head: :no_content
      return
    end

    Rails.application.eager_load! unless Rails.application.config.cache_classes

    clazz = table.classify
    if Object.const_defined? clazz
      model = clazz.constantize
      if model < ApplicationRecord
        render json: model.columns_hash.map { |k, v| "#{k}: #{v.sql_type_metadata.sql_type}" }
      else
        render status: :forbidden, plain: 'Requested table does not map to a valid ActiveRecord model'
      end
    else
      render status: :not_found, plain: 'Requested table does not have a valid class equivalent'
    end
  end

  private

  def data_params
    params.permit(types: [], limits: {})
  end

  def public_fields(type, const)
    sensitive = AppConfig['sensitive_fields'].select { |x| x.start_with? "#{type}." }.map { |x| x.gsub("#{type}.", '') }
    const.attribute_names - sensitive
  end
end
