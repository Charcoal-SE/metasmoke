# frozen_string_literal: true

class DeveloperController < ApplicationController
  before_action :authenticate_user!, except: [:blank_page]
  before_action :verify_developer, except: %i[blank_page change_back verify_elevation]
  before_action :check_impersonating, only: %i[change_back verify_elevation]

  def update_sites
    SitesHelper.update_sites
    flash[:info] = 'Site cache updated, refer to MiniProfiler for execution details.'
    redirect_back(fallback_location: url_for(controller: :dashboard, action: :index))
  end

  def production_log
    @log = if params[:grep].present?
             unless params[:context].respond_to?(:to_i)
               flash[:warning] = "Coercion failure on params[:context]: Can't convert to an interger"
               redirect_to(root_path) && return
             end
             `tail -n 10000 log/production.log | grep -E '#{params[:grep].to_s.tr("'", '')}' -C '#{params[:context].to_i}' --color=never`
           else
             `tail -n 1000 log/production.log`
           end

    # Don't modify frozen strings
    @log.gsub(/\e\[([;\d]+)?m/, '') # Terminal color codes
    @log.gsub(/\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/, '') # IPs
    @log.gsub(/\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}\b/i, '') # Emails
  end

  def make_space_in_logs
    redis(logger: true).zrange('requests', 0, -1, with_scores: true).each do |val, score|
      new_expire = REDIS_LOG_EXPIRATION.to_i - (Time.now.to_i - score.to_i)
      keys = redis(logger: true).scan_each(match: "request/#{score}*").to_a
      redis(logger: true).multi do
        if new_expire <= 0
          keys.each { |k| redis(logger: true).del(k) }
          redis(logger: true).zrem 'requests', val
        else
          keys.each do |k|
            redis(logger: true).expire k, new_expire
          end
        end
      end
    end
  end

  def deploy
    message = "[ [metasmoke-deploy](//github.com/Undo1/metasmoke-deploy/actions) ] deploy started by #{current_user.username}"
    SmokeDetector.send_message_to_charcoal(message)

    Octokit.workflow_dispatch("Undo1/metasmoke-deploy", "deploy.yml", "master")

    redirect_to 'https://github.com/Undo1/metasmoke-deploy/actions'
  end

  def query_times_log
    send_file 'log/query_times.log'
  end

  def blank_page
    render layout: false
  end

  def empty_layout
    render layout: true
  end

  def websocket_test; end

  def send_websocket_test
    ActionCable.server.broadcast params[:channel], JSON.parse(params[:content])
    flash[:info] = 'Queued for broadcast.'
    redirect_to url_for(controller: :developer, action: :websocket_test)
  end

  def change_users
    dev_id = current_user.id
    @user = User.find params[:id]
    sign_in @user
    session[:impersonator_id] = dev_id
    flash[:success] = "You are now impersonating #{@user.username}."
    redirect_to root_path
  end

  def change_back
    @impersonator = User.find session[:impersonator_id]
  end

  def verify_elevation
    @impersonator = User.find session[:impersonator_id]
    if @impersonator&.valid_password? params[:password]
      session.delete :impersonator_id
      sign_in @impersonator
      redirect_to root_path
    else
      flash[:danger] = 'Incorrect password.'
      render :change_back
    end
  end

  def run_fcrs
    ConflictingFeedbackJob.perform_later
    flash[:success] = 'ConflictingFeedbackJob triggered.'
    redirect_back fallback_location: root_path
  end

  def run_feedback_reindex
    FeedbackReindexJob.perform_later
    flash[:success] = 'FeedbackReindexJob triggered.'
    redirect_back fallback_location: root_path
  end

  private

  def check_impersonating
    require_developer unless session[:impersonator_id].present?
  end
end
