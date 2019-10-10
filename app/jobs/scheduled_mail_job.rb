# frozen_string_literal: true

class ScheduledMailJob < ApplicationJob
  queue_as :default

  def perform(*_args)
    Emails::Preference.joins(:addressee, :type, :reference)
                      .where(Arel.sql('next IS NOT NULL AND next <= CURRENT_TIMESTAMP AND enabled = TRUE')).each do |ep|
      mailer = "#{ep.type.mailer}Mailer".constantize
      mailer.send(ep.type.method_name, ep)
    end
  end
end
