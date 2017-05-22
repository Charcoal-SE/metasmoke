# frozen_string_literal: true

class StatisticsController < ApplicationController
  protect_from_forgery except: [:create]
  before_action :check_if_smokedetector, only: [:create]

  # GET /statistics
  def index
    @smoke_detector = SmokeDetector.find(params[:id])
    @statistics = @smoke_detector.statistics.paginate(page: params[:page], per_page: 100).order('created_at DESC')
  end

  # POST /statistics.json
  def create
    @statistic = Statistic.new(statistic_params)

    if @statistic.posts_scanned == 0 || @statistic.api_quota == -1
      render(plain: 'OK', status: :created) && return
    end

    @statistic.smoke_detector = @smoke_detector

    respond_to do |format|
      if @statistic.save
        format.json { render plain: 'OK', status: :created }
      else
        format.json { render json: @statistic.errors, status: :unprocessable_entity }
      end
    end
  end

  private

  # Never trust parameters from the scary internet, only allow the white list through.
  def statistic_params
    params.require(:statistic).permit(:posts_scanned, :api_quota, :post_scan_rate)
  end
end
