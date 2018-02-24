# frozen_string_literal: true

class DeveloperController < ApplicationController
  before_action :authenticate_user!, except: [:blank_page]
  before_action :verify_developer, except: [:blank_page]

  def update_sites
    SitesHelper.update_sites
    flash[:info] = 'Site cache updated, refer to MiniProfiler for execution details.'
    redirect_back(fallback_location: url_for(controller: :dashboard, action: :index))
  end

  def production_log
    @log = if params[:grep].present?
             `grep -E '#{params[:grep]}' -C #{params[:context]} --color=never`
           else
             `tail -n 1000 log/production.log`
           end

    # Don't modify frozen strings
    @log.gsub(/\e\[([;\d]+)?m/, '') # Terminal color codes
    @log.gsub(/\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/, '') # IPs
    @log.gsub(/\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}\b/i, '') # Emails
  end

  def blank_page
    render layout: false
  end

  def websocket_test; end

  def send_websocket_test
    ActionCable.server.broadcast params[:channel], JSON.parse(params[:content])
    flash[:info] = 'Queued for broadcast.'
    redirect_to url_for(controller: :developer, action: :websocket_test)
  end
end
