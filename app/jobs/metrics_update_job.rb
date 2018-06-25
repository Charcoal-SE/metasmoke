# frozen_string_literal: true

class MetricsUpdateJob < ApplicationJob
  queue_as :default

  def perform(path, db_runtime)
    route = Rails.sensible_routes.match_for path
    normalized_path = "#{route.verb} #{route.path}"

    query = QueryAverage.find_or_create_by(path: normalized_path)
    query.average = (query.average * query.counter + db_runtime) / (query.counter += 1)
    query.save
  end
end
