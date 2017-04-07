class UsersController < ApplicationController
  before_action :authenticate_user!

  def username

  end

  def set_username
    current_user.username = params[:username]
    current_user.save!

    redirect_to dashboard_path
  end

  def apps
    @keys = ApiKey.find(current_user.api_tokens.pluck(:api_key_id))
  end

  def revoke_app
    @key = ApiKey.find params[:key_id]
    @tokens = ApiToken.where(:api_key => @key, :user => current_user)
    if @tokens.destroy_all
      flash[:success] = "Revoked access to your account from #{@key.app_name}."
    else
      flash[:danger] = "Could not revoke access - contact a metasmoke admin."
    end
    redirect_to url_for(:controller => :users, :action => :apps)
  end

  def tf_status
  end

  def enable_2fa
    secret = ROTP::Base32.random_base32
    current_user.update(:two_factor_token => secret)
    totp = ROTP::TOTP.new(secret, issuer: 'metasmoke')
    uri = totp.provisioning_uri("#{current_user.id}@metasmoke.erwaysoftware.com")
    qr_svg = RQRCode::QRCode.new(uri).as_svg
    @qr_uri = "data:image/svg+xml;base64,#{Base64.encode64(qr_svg)}"
  end

  def enable_code
  end

  def confirm_enable_code
    unless current_user.two_factor_token.present?
      flash[:danger] = "Missed a step! There's no 2FA token on your account."
      redirect_to url_for(:controller => :users, :action => :tf_status) and return
    end

    totp = ROTP::TOTP.new(current_user.two_factor_token)
    if totp.verify_with_drift(params[:code], 30, Time.now)
      current_user.update(:enabled_2fa => true)
      flash[:success] = "Success! 2FA has been enabled on your account."
      redirect_to url_for(:controller => :users, :action => :tf_status)
    else
      flash[:danger] = "That's not the right code."
      redirect_to url_for(:controller => :users, :action => :enable_code)
    end
  end

  def disable_code
  end

  def confirm_disable_code
    unless current_user.two_factor_token.present?
      flash[:danger] = "I don't know how you got here, but something is badly wrong."
      redirect_to url_for(:controller => :users, :action => :tf_status) and return
    end

    totp = ROTP::TOTP.new(current_user.two_factor_token)
    if totp.verify_with_drift(params[:code], 30, Time.now)
      current_user.update(:two_factor_token => nil, :enabled_2fa => false)
      flash[:success] = "Success! 2FA has been disabled on your account."
      redirect_to url_for(:controller => :users, :action => :tf_status)
    else
      flash[:danger] = "That's not the right code."
      redirect_to url_for(:controller => :users, :action => :disable_code)
    end
  end
end
