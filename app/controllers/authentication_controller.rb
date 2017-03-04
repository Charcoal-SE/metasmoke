require 'open-uri'
include AuthenticationHelper

class AuthenticationController < ApplicationController
  before_action :authenticate_user!, :except => [:login_redirect_target]
  before_action :verify_admin, :only => [:invalidate_tokens, :send_invalidations]

  def status
    @config = AppConfig["stack_exchange"]
  end

  def redirect_target
    token = access_token_from_code(params[:code])
    access_token_info = info_for_access_token(token)

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

    if current_user.api_token.present? and current_user.flags_enabled == false
      redirect_to ocs_path
    else
      redirect_to authentication_status_path
    end
  end

  def login_redirect_target
    if user_signed_in?
      flash[:error] = "You're already signed in."
      redirect_to root_path and return
    end

    token = access_token_from_code(params[:code], AppConfig["stack_exchange"]["login_redirect_uri"])
    access_token_info = info_for_access_token(token)

    user = User.find_by_stack_exchange_account_id(access_token_info["account_id"])

    if user.present?
      flash[:success] = "Successfully logged in as #{user.username}"
      sign_in_and_redirect user
    else
      user = User.new(stack_exchange_account_id: access_token_info["account_id"],
                      email: "#{access_token_info["account_id"]}@se-oauth.metasmoke")

      user.username = user.get_username(token)

      user.password = user.password_confirmation = SecureRandom.hex

      user.save!

      Thread.new do
        # Do this in the background to keep the page load fast.
        user.update_chat_ids
        user.save!
      end

      flash[:success] = "New account created for #{user.username}. Have fun!"
      sign_in_and_redirect user
    end
  end

  def invalidate_tokens
    @users = User.all.where.not(:api_token => nil)
  end

  def send_invalidations
    users = User.where(:id => params[:users])
    Thread.new do
      token_groups = users.map(&:api_token).in_groups_of(20).map(&:compact)
      token_groups.each do |group|
        uri = "https://api.stackexchange.com/2.2/access-tokens/#{group.join(";")}/invalidate"
        HTTParty.get(uri)
      end

      users.update_all(:api_token => nil)
    end
    flash[:info] = "Token invalidations queued."
    redirect_to url_for(:controller => :authentication, :action => :invalidate_tokens)
  end
end
