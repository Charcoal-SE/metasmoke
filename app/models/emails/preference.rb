class Emails::Preference < ApplicationRecord
  belongs_to :type, class_name: 'Emails::Type', foreign_key: 'emails_type_id'
  belongs_to :addressee, class_name: 'Emails::Addressee', foreign_key: 'emails_addressee_id'
  belongs_to :reference, polymorphic: true

  def self.sign_up_for_emails(email_address:, name: nil, type_short:, frequency_days:, consent_via:, consent_comment:, reference:)
    type = Emails::Type[type_short]
    if type.nil?
      throw "Unrecognized email type `#{type_short}'. Email types must be created manually before use."
    end

    addressee = Emails::Addressee.find_by(email_address: email_address)
    if addressee.nil?
      addressee = Emails::Addressee.create(name: name, email_address: email_address)
    end

    Emails::Preference.create(type: type, addressee: addressee, consent_via: consent_via, consent_comment: consent_comment, enabled: true,
                              frequency: frequency_days, next: (Date.today + frequency_days.to_i.days).to_time.iso8601, reference: reference)
  end
end
