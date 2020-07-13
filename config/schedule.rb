# frozen_string_literal: true

every 1.day, at: '1:00 am' do
  runner 'ReasonsHelper.check_for_inactive_reasons'
  runner 'ReasonsHelper.calculate_weights_for_flagging'
end

every 1.day, at: '6:00 pm' do
  runner 'SitesHelper.update_sites'
end

# Run moderator check about an hour before the spam waves.
# We don't want to run it *during* the spam wave,
# as that could cause us to get unrespected API backoffs.

every 1.day, at: '2:00 am' do
  runner 'User.where.not(stack_exchange_account_id: nil).each { |u| u.update_moderator_sites; sleep(5) }'
  runner 'FlagCondition.revalidate_all'
  runner 'AbuseReport.update_stale_reports'
  runner 'ConflictingFeedbackJob.perform_later'
end

# every 1.day, at: '3:10am' do
#   runner 'ApplicationRecord.full_dump'
# end

every 1.day, at: '3:00am' do
  runner 'ScheduledMailJob.perform_later'
end
