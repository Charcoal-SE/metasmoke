# frozen_string_literal: true

class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :check_auth_required
  before_action :deduplicate_ajax_requests

  before_action do
    Rack::MiniProfiler.authorize_request if current_user&.has_role?(:developer)
  end

  def check_if_smokedetector
    Rack::MiniProfiler.step('ApplicationController: check_if_smokedetector') do
      provided_key = params[:key]

      @smoke_detector = SmokeDetector.find_by(access_token: provided_key)

      return if @smoke_detector.present? # Authorized
      render(plain: 'Go away', status: 403)
    end
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

  Role.names.each do |rn|
    define_method "verify_#{rn}" do
      return if user_signed_in? && current_user.has_role?(rn)
      redirect_to missing_privileges_path(required: rn)
    end
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:username, :eu_resident, :privacy_accepted])
    devise_parameter_sanitizer.permit(:account_update, keys: [:username])
  end

  def verify_at_least_one_diamond
    return if user_signed_in? && current_user.moderator_sites.exists?
    redirect_to missing_privileges_path(required: :at_least_one_diamond)
  end

  private

  def check_auth_required
    return unless Redis::SiteSetting.bool('require_auth_all_pages')
    return if user_signed_in? || devise_controller? || (controller_name == 'users' && action_name == 'missing_privileges')
    flash[:warning] = 'You need to have an account to view metasmoke pages.'
    authenticate_user!
  end

  def deduplicate_ajax_requests
    return unless request.headers['X-AJAX-Deduplicate'].present?

    request_uniq = request.headers['X-AJAX-Deduplicate']
    if !redis.set "request-dedup/#{request_uniq}", 1, ex: 300, nx: true
      render status: :conflict, plain: "409 Conflict\nRequest conflicts with a previous AJAX request"
    end
  end
end
