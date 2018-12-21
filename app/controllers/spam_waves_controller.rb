# frozen_string_literal: true

class SpamWavesController < ApplicationController
  before_action :verify_admin
  before_action :set_wave, except: [:index, :new, :create, :preview]

  def index
    @active = SpamWave.active.order(created_at: :desc).paginate(page: params[:page], per_page: 30)
    @expired = SpamWave.expired.order(created_at: :desc).paginate(page: params[:page], per_page: 30)
  end

  def show; end

  def new
    @errors = []
  end

  def create
    sites = params[:sites].present? && params[:sites].respond_to?(:map) ? params[:sites].map { |s| Site.find(s) } : []
    @wave = SpamWave.new(name: params[:name], user: current_user, expiry: params[:expiry], max_flags: params[:max_flags],
                         conditions: params[:conditions], sites: sites, created_at: DateTime.now)
    if @wave.save
      redirect_to spam_wave_path(@wave)
    else
      @errors = @wave.errors
      render :new
    end
  end

  def preview
    sites = params[:sites].present? && params[:sites].respond_to?(:map) ? params[:sites].map { |s| Site.find(s) } : []
    @wave = SpamWave.new(name: params[:name], user: current_user, expiry: params[:expiry], max_flags: params[:max_flags],
                         conditions: params[:conditions], sites: sites, created_at: DateTime.now)
    posts = @wave.posts
    @posts = Post.where(id: posts.map(&:id)).includes_for_post_row.order(created_at: :desc)
    @accuracy = !posts.empty? ? (posts.select(&:is_tp).size.to_f / posts.size.to_f) * 100 : 0.0
    render :preview, format: :js
  end

  def edit
    @errors = []
  end

  def update
    sites = params[:sites].present? && params[:sites].respond_to?(:map) ? params[:sites].map { |s| Site.find(s) } : []
    if @wave.update(name: params[:name], user: current_user, expiry: params[:expiry], max_flags: params[:max_flags],
                    conditions: params[:conditions], sites: sites)
      redirect_to spam_wave_path(@wave)
    else
      @errors = @wave.errors
      render :edit
    end
  end

  def cancel
    @wave.update(expiry: DateTime.now)
    flash[:success] = 'Cancelled wave.'
    redirect_back fallback_location: spam_wave_path(@wave)
  end

  def renew
    @wave.update(expiry: 24.hours.from_now)
    flash[:success] = 'Renewed wave for 24 hours.'
    redirect_back fallback_location: spam_wave_path(@wave)
  end

  private

  def set_wave
    @wave = SpamWave.find params[:id]
  end
end
