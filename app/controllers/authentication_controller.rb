require 'open-uri'

class AuthenticationController < ApplicationController
  before_action :authenticate_user!
  def status
    @config = AppConfig["stack_exchange"]
  end

  def redirect_target
    config = AppConfig["stack_exchange"]

    request_params = { "client_id" => config["client_id"], "client_secret" => config["client_secret"], "code" => params[:code], "redirect_uri" => config["redirect_uri"] }
    response = Rack::Utils.parse_nested_query(Net::HTTP.post_form(URI.parse('https://stackexchange.com/oauth/access_token'), request_params).body)

    token = response["access_token"]

    access_token_info = JSON.parse(open("https://api.stackexchange.com/2.2/access-tokens/#{token}?key=#{config["key"]}").read)["items"][0]

    current_user.stack_exchange_account_id = access_token_info["account_id"]
    current_user.update_chat_ids

    begin
      current_user.api_token = token if access_token_info["scope"].include? "write_access"
    rescue
    end

    # temporarily disable SQL logging. http://stackoverflow.com/a/7760140/1849664
    old_logger = ActiveRecord::Base.logger
    ActiveRecord::Base.logger = nil

    current_user.save!

    ActiveRecord::Base.logger = old_logger

    if current_user.api_token.present?
      u = current_user
      Thread.new do
        # Do this in the background to keep the page load fast.
        u.update_moderator_sites
      end
    end

    flash[:success] = "Successfully registered #{'write' if current_user.api_token.present?} token"

    redirect_to authentication_status_path
  end
end
