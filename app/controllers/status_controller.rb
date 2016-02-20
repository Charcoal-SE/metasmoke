class StatusController < ApplicationController
  protect_from_forgery :except => [:status_update]
  before_filter :check_if_smokedetector, :only => [:status_update]

  def index
  end

  def status_update
    @smoke_detector.last_ping = DateTime.now
    @smoke_detector.location = params[:location]

    @smoke_detector.save!

    respond_to do |format|
      format.json { render status: :created, :text => "OK" }
    end
  end
end
