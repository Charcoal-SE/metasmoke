# frozen_string_literal: true

class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  before_action :configure_permitted_parameters, if: :devise_controller?

  def check_if_smokedetector
    provided_key = params[:key]

    @smoke_detector = SmokeDetector.find_by_access_token(provided_key)

    return if @smoke_detector.present? # Authorized
    render(plain: 'Go away', status: 403)
  end

  def not_found
    raise ActionController::RoutingError, 'Not Found'
  end

  def after_sign_in_path_for(resource_or_scope)
    if current_user.username.nil?
      users_username_path
    elsif current_user.stack_exchange_account_id.nil?
      authentication_status_path
    else
      stored_location = nil
      begin
        stored_location = stored_location_for(resource_or_scope)
      rescue # rubocop:disable Lint/HandleExceptions
      end

      request.env['omniauth.origin'] || stored_location || root_path
    end
  end

  protected

  def verify_developer
    return if user_signed_in? && current_user.has_role?(:admin)
    raise ActionController::RoutingError, 'Not Found'
  end

  def verify_admin
    return if user_signed_in? && current_user.has_role?(:admin)
    raise ActionController::RoutingError, 'Not Found'
  end

  def verify_code_admin
    return if user_signed_in? && current_user.has_role?(:code_admin)
    raise ActionController::RoutingError, 'Not Found'
  end

  def verify_flagger
    return if user_signed_in? && current_user.has_role?(:flagger)
    raise ActionController::RoutingError, 'Not Found'
  end

  def verify_reviewer
    return if user_signed_in? && current_user.has_role?(:reviewer)
    raise ActionController::RoutingError, 'Not Found'
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:username])
  end
end
