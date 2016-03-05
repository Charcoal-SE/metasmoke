class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  # before_action do
  #   Rack::MiniProfiler.authorize_request
  # end

  def check_if_smokedetector
    provided_key = params[:key]

    @smoke_detector = SmokeDetector.find_by_access_token(provided_key)

    if @smoke_detector.present?
      return # Authorized
    else
      render :text => "Go away" and return
    end
  end

  def not_found
    raise ActionController::RoutingError.new('Not Found')
  end
end
