# frozen_string_literal: true

class AbuseReportsController < ApplicationController
  before_action :verify_core, except: [:public_link]
  before_action :set_report, except: %i[index new create public_link]
  before_action :verify_access, except: %i[index new create show public_link]
  before_action :verify_admin, only: [:destroy]

  def index
    case params[:filter]
    when 'closed'
      ids = [AbuseReportStatus['Closed: Successful'].id, AbuseReportStatus['Closed: Unsuccessful'].id]
      @reports = AbuseReport.where(abuse_report_status_id: ids).paginate(page: params[:page], per_page: 90)
    when 'stale'
      @reports = AbuseReport.where(status: AbuseReportStatus['Stale']).paginate(page: params[:page], per_page: 90)
    else # includes when 'open'
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
      flash[:danger] = "Failed to open new report:\n#{@report.errors.full_messages.join("\n")}"
      redirect_to new_abuse_report_path(reportable_type: @report.reportable_type, reportable_id: @report.reportable_id)
    end
  end

  def show
    @reportable_path = {
      'DomainTag' => domain_tag_path(@report.reportable),
      'Post' => post_path(@report.reportable),
      'SpamDomain' => spam_domain_path(@report.reportable)
    }[@report.reportable_type]
  end

  def public_link
    @report = AbuseReport.find_by_uuid params[:uuid]
    @reportable_path = {
      'DomainTag' => domain_tag_path(@report.reportable),
      'Post' => post_path(@report.reportable),
      'SpamDomain' => spam_domain_path(@report.reportable)
    }[@report.reportable_type]
    render :show
  end

  def update
    if @report.update report_params
      flash[:success] = 'Updated report.'
    else
      flash[:danger] = 'Failed to update report.'
    end
    redirect_back fallback_location: abuse_report_path(@report)
  end

  def update_status
    old_status = @report.status.name
    status = AbuseReportStatus.find params[:status_id]
    new_status = status.name
    if @report.update status: status
      AbuseComment.create user: User.find(-1), report: @report,
                          text: "**#{current_user.username}** updated the status from **#{old_status}** to **#{new_status}**"
      flash[:success] = 'Updated status.'
    else
      flash[:danger] = 'Failed to update status.'
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
    return if current_user == @report.user || current_user&.has_role?(:admin)

    not_found
  end
end
