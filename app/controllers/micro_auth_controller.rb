class MicroAuthController < ApplicationController
  before_action :authenticate_user!, :except => [:token]
  before_action :verify_key, :except => [:reject]

  def request
  end

  def authorize
    @token = ApiToken.new(:user => current_user, :api_key => @api_key, :code => generate_code(7), :token => generate_code(64), :expiry => 10.minutes.from_now)
    if !@token.save
      flash[:alert] = "Can't create a write token right now - ask an admin to look at the server logs."
      redirect_to url_for(:controller => :micro_auth, :action => :request) and return
    end
  end

  def reject
  end

  def token
    code = params[:code]
    token = ApiToken.where(:code => code, :api_key => @api_key)
    if token.any? && !token.first.expiry.past?
      render :json => { :token => token.first.token }
    else
      render :json => { :error_name => 'token not found', :error_code => 404, :error_message => 'There was no token found matching the key and code.' }, :status => 404
    end
  end

  def invalid_key
  end

  private
    def generate_code(len)
      hash = Digest::SHA256.hexdigest("#{rand(0..9e9)}#{Time.now}")
      return hash[0..(len - 1)]
    end

    def verify_key
      @api_key = ApiKey.find_by_key(params[:key])
      unless params[:key].present? && @key.present?
        render :invalid_key, :status => 400 and return
      end
    end
end
