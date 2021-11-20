# frozen_string_literal: true

class Emails::Preference < ApplicationRecord
  belongs_to :type, class_name: 'Emails::Type', foreign_key: 'emails_type_id'
  belongs_to :addressee, class_name: 'Emails::Addressee', foreign_key: 'emails_addressee_id'
  belongs_to :reference, polymorphic: true

  # rubocop:disable Metrics/ParameterLists
  def self.sign_up_for_emails(email_address:, type_short:, frequency_days:, consent_via:, consent_comment:, reference:, name: nil)
    type = Emails::Type[type_short]
    throw "Unrecognized email type `#{type_short}'. Email types must be created manually before use." if type.nil?

    addressee = Emails::Addressee.find_by(email_address: email_address)
    addressee = Emails::Addressee.create(name: name, email_address: email_address) if addressee.nil?

    ep = Emails::Preference.create(type: type, addressee: addressee, consent_via: consent_via, consent_comment: consent_comment, enabled: true,
                                   frequency: frequency_days, next: (Date.today + frequency_days.to_i.days).to_time.iso8601, reference: reference)
    mailer = "#{type.mailer}Mailer".constantize
    mailer.send(type.method_name, ep)
  end
  # rubocop:enable Metrics/ParameterLists
end
