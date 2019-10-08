class Emails::Preference < ApplicationRecord
  belongs_to :type, class_name: 'Emails::Type'
  belongs_to :addressee, class_name: 'Emails::Addressee'
  belongs_to :reference, polymorphic: true

  def self.sign_up_for_emails(email_address:, name: nil, type_short:, frequency_days:, consent_via:, consent_comment:, reference:)
    type = Emails::Type[type_short]
    if type.nil?
      throw "Unrecognized email type `#{type_short}'. Email types must be created manually before use."
    end

    addressee = Emails::Addressee.find_by(email_address: email_address)
    if addressee.nil?
      addressee = Emails::Addressee.create(name: name, email_address: email_address, manage_key: SecureRandom.hex(32))
    end

    Emails::Preference.create(type: type, addressee: addressee, consent_via: consent_via, consent_comment: consent_comment,
                              frequency: frequency_days, next: (Date.today + frequency_days.days).to_time.iso8601, reference: reference)
  end
end
