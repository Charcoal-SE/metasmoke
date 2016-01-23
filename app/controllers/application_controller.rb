class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  # before_action do
  #   Rack::MiniProfiler.authorize_request
  # end

  def check_if_smokedetector
    ip = request.remote_ip
    if ip == "::1" or ip == "127.0.0.1"
      return # Authorized
    end

    expected_key = AppConfig["smoke_detector"]["key"]
    provided_key = params[:key]

    if expected_key == provided_key
      return # Authorized
    else
      render :text => "Go away" and return
    end
  end
end
