# frozen_string_literal: true

class SmokeDetectorsController < ApplicationController
  before_action :authenticate_user!, except: %i[audits check_token]
  before_action :verify_admin, except: %i[audits force_failover force_pull mine token_regen new create check_token]
  before_action :verify_blacklist_manager, only: %i[force_failover force_pull]
  before_action :verify_smoke_detector_runner, only: %i[mine token_regen new create]
  before_action :set_smoke_detector, except: %i[audits mine new create check_token]

  def destroy
    unless current_user.present? && (current_user.has_role?(:admin) || current_user.id == @smoke_detector.user_id)
      raise ActionController::RoutingError, 'Not Found'
    end

    if @smoke_detector.destroy
      flash[:success] = "Removed SmokeDetector key for #{@smoke_detector.location}"
    else
      flash[:danger] = "Can't remove key. If Undo's gone rogue, start running."
    end

    redirect_to params[:redirect] || status_path
  end

  def force_failover
    @smoke_detector.update(force_failover: true)
    flash[:success] = "Failover for #{@smoke_detector.location} will be forced on the next ping; probably within 60 seconds."

    redirect_to status_path
  end

  def force_pull
    @smoke_detector.update(force_pull: true)
    flash[:success] = "#{@smoke_detector.location} will pull updates on the next ping; probably within 60 seconds."

    redirect_to status_path
  end

  def audits
    @audits = Audited::Audit.where(auditable_type: 'SmokeDetector')
                            .includes(:auditable, :user)
                            .order(Arel.sql('created_at DESC'))
                            .paginate(page: params[:page], per_page: 100)
  end

  def mine
    @smoke_detectors = current_user.smoke_detectors
  end

  def new
    @smoke_detector = current_user.smoke_detectors.new
  end

  def create
    @smoke_detector = SmokeDetector.new(smoke_detector_params)
    @smoke_detector.location = @smoke_detector.name

    @smoke_detector.last_ping = 100.years.ago
    @smoke_detector.email_date = 99.years.ago

    @smoke_detector.access_token = SecureRandom.uuid
    @smoke_detector.user = current_user

    if @smoke_detector.save
      flash[:success] = "Successfully created new token: #{@smoke_detector.access_token}"
    else
      flash[:danger] = 'Something went wrong when saving SmokeDetector'
    end

    redirect_to smoke_detector_mine_path
  end

  def token_regen
    unless current_user.present? && current_user.id == @smoke_detector.user_id
      raise ActionController::RoutingError, 'Not Found'
    end

    if @smoke_detector.update(access_token: SecureRandom.uuid)
      flash[:success] = "Access token for #{@smoke_detector.location} updated to #{@smoke_detector.access_token}"
    else
      flash[:danger] = 'Something went wrong'
    end

    redirect_to params[:redirect] || smoke_detector_mine_path
  end

  # Used by Helios to verify new tokens
  def check_token
    token = SmokeDetector.where(access_token: params[:token]).first
    payload = {
      exists: token.present?,
      owner_name: token&.user&.username,
      location: token&.location,
      created_at: token&.created_at,
      updated_at: token&.updated_at
    }

    render json: payload
  end

  private

  def set_smoke_detector
    @smoke_detector = SmokeDetector.find params[:id]
  end

  def smoke_detector_params
    params.require(:smoke_detector).permit(:name)
  end
end
