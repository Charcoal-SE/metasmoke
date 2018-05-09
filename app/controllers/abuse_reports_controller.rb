# frozen_string_literal: true

class AbuseReportsController < ApplicationController
  before_action :verify_core
  before_action :set_report, except: [:index, :new, :create]
  before_action :verify_access, except: [:index, :new, :create]
  before_action :verify_admin, only: [:destroy]

  def index
    case params[:filter]
    when 'closed'
      ids = [AbuseReportStatus['Closed: Successful'].id, AbuseReportStatus['Closed: Unsuccessful'].id]
      @reports = AbuseReport.where(abuse_report_status_id: ids).paginate(page: params[:page], per_page: 90)
    when 'stale'
      @reports = AbuseReport.where(status: AbuseReportStatus['Stale']).paginate(page: params[:page], per_page: 90)
    when 'open'
      @reports = AbuseReport.where(status: AbuseReportStatus['Open']).paginate(page: params[:page], per_page: 90)
    else
      @reports = AbuseReport.where(status: AbuseReportStatus['Open']).paginate(page: params[:page], per_page: 90)
    end
  end

  def new; end

  def create
    @report = AbuseReport.new report_params.merge(user: current_user)
    if @report.save
      flash[:success] = "Opened new abuse report ##{@report.id}."
      redirect_to abuse_report_path(@report)
    else
      flash[:danger] = 'Failed to open new report.'
      redirect_to new_abuse_report_path(reportable_type: @report.reportable_type, reportable_id: @report.reportable_id)
    end
  end

  def show; end

  def update
    if @report.update report_params
      flash[:success] = 'Updated report.'
    else
      flash[:danger] = 'Failed to update report.'
    end
    redirect_back fallback_location: abuse_report_path(@report)
  end

  def destroy
    if @report.destroy
      flash[:success] = 'Removed report.'
      redirect_to abuse_reports_path
    else
      flash[:danger] = 'Failed to remove report.'
      redirect_to abuse_report_path(@report)
    end
  end

  private

  def report_params
    params.require(:abuse_report).permit(:reportable_type, :reportable_id, :abuse_contact_id, :details)
  end

  def set_report
    @report = AbuseReport.find params[:id]
  end

  def verify_access
    current_user == @report.user || current_user&.has_role?(:admin)
  end
end
