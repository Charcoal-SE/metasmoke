# frozen_string_literal: true

require 'open-uri'
include AuthenticationHelper

class AuthenticationController < ApplicationController
  before_action :authenticate_user!, except: [:login_redirect_target]
  before_action :verify_admin, only: %i[invalidate_tokens send_invalidations]

  def status
    @config = AppConfig['stack_exchange']
  end

  def redirect_target
    token = access_token_from_code(params[:code])
    access_token_info = info_for_access_token(token)

    current_user.stack_exchange_account_id = access_token_info['account_id']
    current_user.update_chat_ids

    # temporarily disable SQL logging. http://stackoverflow.com/a/7760140/1849664
    old_logger = ActiveRecord::Base.logger
    ActiveRecord::Base.logger = nil

    current_user.save!

    ActiveRecord::Base.logger = old_logger

    if current_user.write_authenticated
      u = current_user
      Thread.new do
        # Do this in the background to keep the page load fast.
        u.update_moderator_sites
      end
    end

    flash[:success] = 'Successfully registered token'

    if current_user.write_authenticated && !current_user.flags_enabled
      redirect_to ocs_path
    else
      redirect_to authentication_status_path
    end
  end

  def login_redirect_target
    if user_signed_in?
      flash[:danger] = "You're already signed in."
      redirect_to(root_path) && return
    end

    token = access_token_from_code(params[:code], AppConfig['stack_exchange']['login_redirect_uri'])
    access_token_info = info_for_access_token(token)

    user = User.find_by(stack_exchange_account_id: access_token_info['account_id'])

    if user.present?
      flash[:success] = "Successfully logged in as #{user.username}"
    elsif !SiteSetting['registration_enabled']
      flash[:warning] = 'Registration is currently disabled.'
      redirect_to root_path
      return
    elsif Rails.cache.read("deleted_user_#{access_token_info['account_id']}").present?
      flash[:warning] = 'You may not recreate your account yet as you have recently deleted it.'
      redirect_to root_path
      return
    else
      user = User.new(stack_exchange_account_id: access_token_info['account_id'],
                      email: "#{access_token_info['account_id']}@se-oauth.metasmoke")

      user.username = user.get_username(token)

      user.password = user.password_confirmation = SecureRandom.hex

      user.save!

      Thread.new do
        # Do this in the background to keep the page load fast.
        user.update_chat_ids
        user.save!
      end

      flash[:success] = "New account created for #{user.username}. Have fun!"
    end
    sign_in_and_redirect user
  end

  def invalidate_tokens
    @users = User.all.where(write_authenticated: true)
  end

  def send_invalidations
    Thread.new do
      User.where(id: params[:users]).each do |user|
        HTTParty.post("#{AppConfig['token_store']['host']}/invalidate_tokens",
          params: { account_id: user.stack_exchange_account_id },
          headers: { 'X-API-Key': AppConfig['token_store']['key'] }
        )
        user.update(write_authenticated: false)
      end
    end
    flash[:info] = 'Token invalidations queued.'
    redirect_to url_for(controller: :authentication, action: :invalidate_tokens)
  end
end
