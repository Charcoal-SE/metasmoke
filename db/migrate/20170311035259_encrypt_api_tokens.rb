# frozen_string_literal: true

class EncryptApiTokens < ActiveRecord::Migration[5.1]
  def up
    encryption_key = AppConfig['stack_exchange']['token_aes_key']

    User.where.not(api_token: nil).each do |u|
      puts u
      u.encrypted_api_token = AESCrypt.encrypt(u.api_token, encryption_key)
      u.save!
    end
  end

  def down; end
end
