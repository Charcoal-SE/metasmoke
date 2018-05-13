require 'json'

logger = Logger.new('log/query_times.log')

logger.formatter = proc do |severity, datetime, progname, msg|
  JSON.generate({time: datetime, msg: msg})
end

ActiveSupport::Notifications.subscribe('process_action.action_controller') do |**info|
  logger.info (info)
end
