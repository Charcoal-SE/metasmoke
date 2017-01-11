class SmokeDetectorsController < ApplicationController
  before_action :authenticate_user!, :except => [:audits]
  before_action :verify_admin, :except => [:audits]
  before_action :set_smoke_detector, :except => [:audits]

  def destroy
    if @smoke_detector.destroy
      flash[:success] = "Removed SmokeDetector key for #{@smoke_detector.location}"
    else
      flash[:danger] = "Can't remove key. If Undo's gone rogue, start running."
    end
    redirect_to url_for(:controller => :status, :action => :index)
  end

  def audits
    @audits = Audited::Audit.where(:auditable_type => "SmokeDetector").includes(:auditable, :user).order('created_at DESC').paginate(:page => params[:page], :per_page => 100)
  end

  private
  def set_smoke_detector
    @smoke_detector = SmokeDetector.find params[:id]
  end
end
