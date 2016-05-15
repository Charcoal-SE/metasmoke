class StatusController < ApplicationController
  protect_from_forgery :except => [:status_update]
  before_action :check_if_smokedetector, :only => [:status_update]

  def index
  end

  def status_update

    commit_update = CommitStatus.where('created_at >= ?', @smoke_detector.last_ping).last

    @smoke_detector.last_ping = DateTime.now
    @smoke_detector.location = params[:location]

    @smoke_detector.save!

    respond_to do |format|
      format.json do
        if commit_update.present?
          render status: 201, :json => commit_update
        else
          render status: 200
        end
      end
    end
  end
end
