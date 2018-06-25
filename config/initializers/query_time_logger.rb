# frozen_string_literal: true

require 'json'

logger = Logger.new('log/query_times.log')

logger.formatter = proc do |_severity, datetime, _progname, msg|
  "#{{ time: datetime, path: msg[:path], db_runtime: msg[:db_runtime] }.to_json}\n"
end

ActiveSupport::Notifications.subscribe('process_action.action_controller') do |**info|
  MetricsUpdateJob.perform_later info[:path], info[:db_runtime]
  logger.info info if SiteSetting['log_query_timings']
end
