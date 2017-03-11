class RemoveReadOnlyTokensFromUsers < ActiveRecord::Migration[5.0]
  def change
    users_to_clear = []

    User.pluck(:api_token).select(&:present?).each_slice(20) do |tokens|
      url = "https://api.stackexchange.com/2.2/access-tokens/#{tokens.join(";")}?key=#{AppConfig["stack_exchange"]["key"]}"
      items = JSON.parse(Net::HTTP.get_response(URI.parse(url)).body)["items"]
      items.each do |i|
        unless i.include? "scope" and i["scope"].include? "write_access"
          users_to_clear << i["account_id"]
        end
      end
    end

    User.where(:stack_exchange_account_id => users_to_clear).update_all(:encrypted_api_token => nil)
  end
end
