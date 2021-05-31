# frozen_string_literal: true

class UsersController < ApplicationController
  before_action :authenticate_user!, except: [:missing_privileges]
  before_action :verify_admin, only: %i[show send_password_reset]
  before_action :verify_developer, only: %i[refresh_ids update_mod_sites]
  before_action :set_user, only: %i[show refresh_ids send_password_reset update_mod_sites]

  def username; end

  def set_username
    current_user.username = params[:username]
    current_user.save!

    redirect_to dashboard_path
  end

  def apps
    @keys = APIKey.find(current_user.api_tokens.pluck(:api_key_id))
  end

  def revoke_app
    @key = APIKey.find params[:key_id]
    @tokens = APIToken.where(api_key: @key, user: current_user)
    if @tokens.destroy_all
      flash[:success] = "Revoked access to your account from #{@key.app_name}."
    else
      flash[:danger] = 'Could not revoke access - contact a metasmoke admin.'
    end
    redirect_to url_for(controller: :users, action: :apps)
  end

  def tf_status; end

  def enable_2fa
    secret = ROTP::Base32.random_base32
    current_user.update(two_factor_token: secret)
    totp = ROTP::TOTP.new(secret, issuer: 'metasmoke')
    uri = totp.provisioning_uri("#{current_user.id}@metasmoke.erwaysoftware.com")
    qr_svg = RQRCode::QRCode.new(uri).as_svg
    @qr_uri = "data:image/svg+xml;base64,#{Base64.encode64(qr_svg)}"
  end

  def enable_code; end

  def confirm_enable_code
    if current_user.two_factor_token.blank?
      flash[:danger] = "Missed a step! There's no 2FA token on your account."
      redirect_to(url_for(controller: :users, action: :tf_status)) && return
    end

    totp = ROTP::TOTP.new(current_user.two_factor_token)
    if totp.verify(params[:code], drift_behind: 30, drift_ahead: 30)
      current_user.update(enabled_2fa: true)
      flash[:success] = 'Success! 2FA has been enabled on your account.'
      redirect_to url_for(controller: :users, action: :tf_status)
    else
      flash[:danger] = "That's not the right code."
      redirect_to url_for(controller: :users, action: :enable_code)
    end
  end

  def disable_code; end

  def confirm_disable_code
    if current_user.two_factor_token.blank?
      flash[:danger] = "I don't know how you got here, but something is badly wrong."
      redirect_to(url_for(controller: :users, action: :tf_status)) && return
    end

    totp = ROTP::TOTP.new(current_user.two_factor_token)
    if totp.verify(params[:code], drift_behind: 30, drift_ahead: 30)
      current_user.update(two_factor_token: nil, enabled_2fa: false)
      flash[:success] = 'Success! 2FA has been disabled on your account.'
      redirect_to url_for(controller: :users, action: :tf_status)
    else
      flash[:danger] = "That's not the right code."
      redirect_to url_for(controller: :users, action: :disable_code)
    end
  end

  def set_announcement_emails
    emails = params[:emails].present?
    if current_user.update(announcement_emails: emails)
      flash[:success] = (emails ? 'Subscribed to' : 'Unsubscribed from') + ' announcement emails.'
    else
      flash[:danger] = 'Failed to save your preferences.'
    end
    redirect_to edit_user_registration_path
  end

  def update_email
    unless /\d+@se-oauth\.metasmoke/.match?(current_user.email)
      flash[:danger] = 'Your email is not the default for an SE OAuth created account.'
      redirect_to edit_user_registration_path
      return
    end

    if current_user.update(email: params[:email])
      flash[:success] = 'Email address updated. You will need to sign out and click "Forgot your password?" on the sign-in page to set your password.'
    else
      flash[:danger] = 'Failed to update your email address.'
    end
    redirect_to edit_user_registration_path
  end

  def missing_privileges
    @role = Role.find_by(name: params[:required])
  end

  def flagging_enabled
    @users = User.where(flags_enabled: true).paginate(per_page: 100, page: params[:page])
  end

  def show; end

  def refresh_ids
    @user.update_chat_ids
    flash[:success] = "Chat IDs refreshed for #{@user.username}."
    redirect_to dev_user_path(@user)
  end

  def send_password_reset
    @user.send_reset_password_instructions
    flash[:success] = "Reset email sent to #{@user.username}."
    redirect_to dev_user_path(@user)
  end

  def update_mod_sites
    @user.update_moderator_sites
    flash[:success] = "Refreshed mod sites list for #{@user.username}."
    redirect_to dev_user_path(@user)
  end

  private

  def set_user
    @user = User.find params[:id]
  end
end
