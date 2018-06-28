# frozen_string_literal: true

class AbuseReportStatusesController < ApplicationController
  before_action :verify_core, except: [:index, :show]
  before_action :set_status, except: [:index, :create]
  before_action :verify_admin, only: :destroy

  def index
    @statuses = AbuseReportStatus.all
  end

  def create
    @status = AbuseReportStatus.new status_params
    if @status.save
      flash[:success] = 'Created status.'
      redirect_back fallback_location: abuse_status_path(@status)
    else
      flash[:danger] = 'Failed to create status.'
      redirect_to abuse_statuses_path
    end
  end

  def show
    @reports = @status.reports.includes(:contact, :status, :user)
  end

  def edit; end

  def update
    if @status.update status_params
      flash[:success] = 'Updated status.'
      redirect_to abuse_status_path(@status)
    else
      flash[:danger] = 'Failed to update.'
      render :edit
    end
  end

  def destroy
    if @status.destroy
      flash[:success] = 'Removed status.'
      redirect_to abuse_statuses_path
    else
      flash[:danger] = 'Failed to remove.'
      redirect_to abuse_status_path(@status)
    end
  end

  private

  def set_status
    @status = AbuseReportStatus.find params[:id]
  end

  def status_params
    params.require(:abuse_report_status).permit(:name, :details, :icon, :color)
  end
end
