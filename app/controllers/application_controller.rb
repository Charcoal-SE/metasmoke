# frozen_string_literal: true

class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :check_auth_required
  before_action :deduplicate_ajax_requests
  before_action :redis_log_request

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

  def redis_log_request
    redis = redis(logger: true)
    Rack::MiniProfiler.step('Logging to redis') do
      redis = redis(logger: true)
      @request_time ||= Time.now.to_f
      request.set_header 'redis_logs.log_key', redis_log_key
      request.set_header 'redis_logs.timestamp', @request_time
      request.set_header 'redis_logs.request_id', request.uuid
      redis.zadd 'requests', @request_time, request.uuid
      log_redis request_headers: headers, params: request.filtered_parameters.except(:controller, :action)
      unless session[:redis_log_id].present?
        session[:redis_log_id] = SecureRandom.base64
        session[:redis_log_id] = SecureRandom.base64 while redis.sadd('sessions', session[:redis_log_id]) == 0
      end
      redis.mapped_hmset redis_log_key, status: 'INC',
                                        path: request.filtered_path,
                                        impersonator_id: session[:impersonator_id],
                                        user_id: user_signed_in? ? current_user.id : nil,
                                        session_id: session[:redis_log_id],
                                        sha: CurrentCommit
      redis.zadd "session/#{session[:redis_log_id]}/requests", @request_time, request.uuid
      redis.hsetnx("session/#{session[:redis_log_id]}", 'start', @request_time)
      redis.hset("session/#{session[:redis_log_id]}", 'end', @request_time)
      redis.zadd "user_sessions/#{current_user.id}", @request_time, session[:redis_log_id] if user_signed_in?
      RedisLogJob.perform_later(request.uuid, @request_time)
    end
  end

  def log_redis(**opts)
    redis = redis(logger: true)
    opts.each do |key, val|
      redis.mapped_hmset "#{redis_log_key}/#{key}", val unless val.empty?
    end
  end

  def redis_log_key
    # We include the time just to doubly ensure that the uuid is unique
    "request/#{@request_time}/#{request.uuid}"
  end

  def check_auth_required
    return unless redis.get('require_auth_all_pages') == '1' # SiteSetting['require_auth_all_pages']
    return if user_signed_in? || devise_controller? || (controller_name == 'users' && action_name == 'missing_privileges')
    flash[:warning] = 'You need to have an account to view metasmoke pages.'
    authenticate_user!
  end

  def deduplicate_ajax_requests
    return unless request.headers['X-AJAX-Deduplicate'].present?

    redis = Redis.new(url: AppConfig['redis']['url'])
    request_uniq = request.headers['X-AJAX-Deduplicate']
    if redis.get("request-dedup/#{request_uniq}").present?
      render status: :conflict, plain: "409 Conflict\nRequest conflicts with a previous AJAX request"
    else
      redis.multi do
        redis.set "request-dedup/#{request_uniq}", '1'
        redis.expire "request-dedup/#{request_uniq}", 300
      end
    end
  end
end
