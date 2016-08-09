require 'open-uri'

class AuthenticationController < ApplicationController
  before_action :authenticate_user! 
  def status
    puts AppConfig

    @config = AppConfig["stack_exchange"]
  end

  def redirect_target
    config = AppConfig["stack_exchange"]

    request_params = { "client_id" => config["client_id"], "client_secret" => config["client_secret"], "code" => params[:code], "redirect_uri" => config["redirect_uri"] }
    resp = Net::HTTP.post_form(URI.parse('https://stackexchange.com/oauth/access_token'), request_params)

    # Possibly fragile, but I *think* it's fine

    token = nil

    begin
      token = resp.body.scan(/access_token=(.*)&/).first.first
    rescue
        
    end

    puts access_token_info = JSON.parse(open("https://api.stackexchange.com/2.2/access-tokens/#{token}?key=#{config["key"]}").read)["items"][0]

    puts current_user.stack_exchange_account_id = access_token_info["account_id"]

    current_user.update_chat_ids

    current_user.save!

    redirect_to authentication_status_path
  end
end
