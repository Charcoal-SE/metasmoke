class UpgradeAesCrypt < ActiveRecord::Migration[5.1]
  def change
    users = User.all.where.not(:encrypted_api_token => nil)
    users.each do |user|
      decrypted = AESCrypt::Migrator.decrypt_from_v1(user.encrypted_api_token, AppConfig['stack_exchange']['token_aes_key'])
      salt, iv, encrypted = AESCrypt.encrypt(decrypted, AppConfig['stack_exchange']['token_aes_key'])
      user.update(:encrypted_api_token => encrypted, :salt => salt, :iv => iv)
    end
  end
end
