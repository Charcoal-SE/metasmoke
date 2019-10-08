class ScheduledMailJob < ApplicationJob
  queue_as :default

  def perform(*args)
    Emails::Preference.joins(:addressee, :type, :reference).where(Arel.sql('next IS NOT NULL AND next <= CURRENT_TIMESTAMP')).each do |ep|
      mailer = "#{ep.mailer}Mailer".constantize
      mailer.send(ep.method_name, ep)
    end
  end
end
