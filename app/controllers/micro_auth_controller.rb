# frozen_string_literal: true

class MicroAuthController < ApplicationController
  before_action :authenticate_user!, except: [:token]
  before_action :verify_key, except: [:invalid_key, :authorized]
  before_action :set_token, only: [:authorized]

  def token_request; end

  def authorize
    unless current_user.has_role?(:reviewer)
      flash[:danger] = 'Your account is not approved to use the write API.'
      redirect_to(url_for(controller: :micro_auth, action: :token_request)) && return
    end

    @token = APIToken.new(user: current_user, api_key: @api_key, code: generate_code(7), token: generate_code(64), expiry: 10.minutes.from_now)
    if @token.save
      redirect_to url_for(controller: :micro_auth, action: :authorized, code: @token.code, token_id: @token.id)
    else
      flash[:danger] = "Can't create a write token right now - ask an admin to look at the server logs."
      redirect_to url_for(controller: :micro_auth, action: :token_request)
    end
  end

  def authorized
    @token = APIToken.find params[:token_id]
    return if current_user.has_role?(:developer) || current_user == @token.user
    raise ActionController::RoutingError, 'https://www.youtube.com/watch?v=6_b7RDuLwcI'
  end

  def reject; end

  def token
    code = params[:code]
    token = APIToken.where(code: code, api_key: @api_key)
    if token.any? && !token.first.expiry.past?
      render json: { token: token.first.token }
    else
      render json: {
        error_name: 'token not found',
        error_code: 404,
        error_message: 'There was no token found matching the key and code.'
      }, status: 404
    end
  end

  def invalid_key; end

  private

  def generate_code(len)
    SecureRandom.hex len
  end

  def verify_key
    @api_key = APIKey.find_by(key: params[:key])
    return if params[:key].present? && @api_key.present?
    render :invalid_key, status: 400
  end

  def set_token
    @token = APIToken.find params[:token_id]
  end
end
