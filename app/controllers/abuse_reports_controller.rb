# frozen_string_literal: true

class AbuseReportsController < ApplicationController
  before_action :verify_core
  before_action :set_report, except: [:index, :new, :create]
  before_action :verify_access, except: [:index, :new, :create]

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
