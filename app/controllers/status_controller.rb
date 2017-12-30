# frozen_string_literal: true

class StatusController < ApplicationController
  include ActionView::Helpers::DateHelper

  protect_from_forgery except: [:status_update]
  before_action :check_if_smokedetector, only: [:status_update]
  before_action :verify_admin, only: [:kill]

  def index
    @statuses = SmokeDetector.order('last_ping DESC').all
  end

  def status_update
    @smoke_detector.last_ping = DateTime.now
    @smoke_detector.location = params[:location]
    @smoke_detector.is_standby = params[:standby] || false

    # If an instance is manually switched to standby, we
    # don't want it to immediately kick back
    new_standby_switch = @smoke_detector.is_standby_changed? && @smoke_detector.is_standby

    @smoke_detector.save!

    ActionCable.server.broadcast 'status',       id: @smoke_detector.id,
                                                 ts_unix: @smoke_detector.last_ping.to_i,
                                                 ts_ago: time_ago_in_words(@smoke_detector.last_ping, include_seconds: true),
                                                 ts_raw: @smoke_detector.last_ping.to_s,
                                                 location: @smoke_detector.location
    ActionCable.server.broadcast 'topbar', last_ping: @smoke_detector.last_ping.to_f
    ActionCable.server.broadcast 'smokey_pings', smokey: @smoke_detector.as_json

    respond_to do |format|
      format.json do
        if @smoke_detector.should_failover && !new_standby_switch
          @smoke_detector.update(is_standby: false, force_failover: false)
          render status: 200, json: { failover: true }
        else
          head 200, content_type: 'text/html'
        end
      end
    end
  end

  def kill
    ActionCable.server.broadcast 'smokedetector_messages', message: { everything_is_broken: true }.to_json
    flash[:success] = 'Kill command sent. I hope you know what you\'re doing.'
    redirect_to status_path
  end
end
