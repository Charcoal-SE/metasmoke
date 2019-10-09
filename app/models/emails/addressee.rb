class Emails::Addressee < ApplicationRecord
  after_create do
    update(manage_key: SecureRandom.hex(32))
  end
end
