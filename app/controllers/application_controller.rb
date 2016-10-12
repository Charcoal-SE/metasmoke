class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :setup_miniprofiler

  def check_if_smokedetector
    provided_key = params[:key]

    @smoke_detector = SmokeDetector.find_by_access_token(provided_key)

    if @smoke_detector.present?
      return # Authorized
    else
      render :plain => "Go away", :status => 403 and return
    end
  end

  def not_found
    raise ActionController::RoutingError.new('Not Found')
  end

  def after_sign_in_path_for(resource_or_scope)
    if current_user.username.nil?
      users_username_path
    elsif current_user.stack_exchange_account_id.nil?
      authentication_status_path
    else
      request.env['omniauth.origin'] || stored_location_for(resource) || root_path
    end
  end

  protected
    def verify_admin
      if !user_signed_in? || !current_user.has_role?(:admin)
        raise ActionController::RoutingError.new('Not Found') and return
      end
    end

    def verify_code_admin
      if !user_signed_in? || !current_user.has_role?(:code_admin)
        raise ActionController::RoutingError.new('Not Found') and return
      end
    end

    def configure_permitted_parameters
      devise_parameter_sanitizer.permit(:sign_up, keys: [:username])
    end

  private
    def setup_miniprofiler
      blacklisted_modes = ['env', 'profile-gc', 'profile-memory', 'analyze-memory']
      unless blacklisted_modes.include? params[:pp]
        Rack::MiniProfiler.authorize_request
      end
    end
end
