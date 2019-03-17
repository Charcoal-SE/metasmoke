# frozen_string_literal: true

class FlagConditionsController < ApplicationController
  before_action :authenticate_user!
  before_action :verify_admin, only: %i[full_list user_overview validate_user]
  before_action :set_condition, only: %i[edit update destroy enable]
  before_action :verify_authorized, only: %i[edit update destroy enable]
  before_action :check_registration_status, only: [:new]
  before_action :set_preview_data, only: %i[new edit preview]
  before_action :verify_reviewer, only: [:sandbox]

  def index
    @conditions = current_user.flag_conditions
  end

  def sandbox
    @condition = FlagCondition.new(site_ids: Site.mains.map(&:id))
  end

  def full_list
    @conditions = FlagCondition.all.includes(:user)
    render :index
  end

  def new
    @condition = FlagCondition.new(site_ids: Site.mains.map(&:id),
                                   min_weight: 280,
                                   max_poster_rep: 1,
                                   min_reason_count: 1)
  end

  def create
    @condition = FlagCondition.new condition_params
    @condition.user = current_user
    @condition.sites = params[:flag_condition][:sites].map { |i| Site.find i.to_i if i.present? }.compact

    if @condition.save
      Thread.new do
        FlagCondition.validate_for_user(current_user, User.find(-1))
      end

      flash[:success] = 'Created a new flagging condition.'
      redirect_to url_for(controller: :flag_conditions, action: :index)
    else
      render :new
    end
  end

  # PATCH /flagging/conditions/:id/toggle
  def enable
    @condition.flags_enabled = !@condition.flags_enabled

    return unless @condition.save
    flash[:success] = "#{@condition.flags_enabled ? 'Enabled' : 'Disabled'} condition."
    redirect_to url_for(controller: :flag_conditions, action: :index)
  end

  def edit
    return if @condition.flags_enabled
    @condition.flags_enabled = true
    @condition.validate

    @validation_errors = @condition.errors.dup
    @condition.restore_attributes
    @condition.errors.clear
  end

  def update
    @condition.sites = params[:flag_condition][:sites].map { |i| Site.find i.to_i if i.present? }.compact
    if @condition.update(condition_params)
      Thread.new do
        FlagCondition.validate_for_user(current_user, User.find(-1))
      end

      flash[:success] = 'Updated your flagging condition.'
      redirect_to url_for(controller: :flag_conditions, action: :index)
    else
      render :edit, status: 422
    end
  end

  def destroy
    if @condition.destroy
      flash[:success] = 'Removed your flagging condition.'
    else
      flash[:danger] = 'Failed to remove the condition - contact a developer to find out why.'
    end
    redirect_to url_for(controller: :flag_conditions, action: :index)
  end

  def preview
    @condition = FlagCondition.new(condition_params)
    set_preview_data

    if params[:filter].present? && !params[:filter].empty?
      if params[:filter] == 'fps'
        @posts = @posts.where('posts.is_fp = TRUE OR posts.is_naa = TRUE')
      elsif params[:filter] == 'tps'
        @posts = @posts.where(is_tp: true)
      end
      @sites = Site.where(id: @posts.map(&:site_id)).to_a
    end

    respond_to do |format|
      format.js
    end
  end

  def one_click_setup
    return if current_user.write_authenticated
    flash[:warning] = 'You need to be write-authenticated before you can set up flagging.'
    redirect_to(url_for(controller: :authentication, action: :status))
  end

  def run_ocs
    if !current_user.write_authenticated
      flash[:warning] = 'You need to be write-authenticated before you can set up flagging.'
      redirect_to(url_for(controller: :authentication, action: :status))
    end

    FlagCondition.create(user: current_user, sites: Site.mains, flags_enabled: true, min_weight: 280, max_poster_rep: 1, min_reason_count: 1)
    UserSiteSetting.create(user: current_user, sites: Site.mains, max_flags: 7)
    current_user.update(flags_enabled: true)

    flash[:info] = "The necessary settings for autoflagging have been created - please review them to make sure you're happy."
    redirect_to url_for(controller: :flag_settings, action: :dashboard)
  end

  def user_overview
    @user = User.find params[:user]
    @conditions = FlagCondition.where(user: @user)
    @preferences = UserSiteSetting.where(user: @user)
    @logs = FlagLog.where(user: @user)
  end

  def validate_user
    @user = User.find params[:user]
    Thread.new do
      FlagCondition.validate_for_user @user, current_user
    end
    flash[:info] = 'Validation launched in background.'
    redirect_back fallback_location: root_path
  end

  private

  def set_condition
    @condition = FlagCondition.find params[:id]
  end

  def condition_params
    params.require(:flag_condition).permit(:min_weight, :max_poster_rep, :min_reason_count, :sites, :flags_enabled)
  end

  def verify_authorized
    return if current_user.has_role?(:admin) || @condition.user == current_user
    raise ActionController::RoutingError, 'Not Found'
  end

  def check_registration_status
    return unless FlagSetting['registration_enabled'] == '0' && !current_user.flags_enabled
    raise ActionController::RoutingError, 'Not Found'
  end

  def set_preview_data
    return unless @condition
    site_ids = if params['flag_condition']
                 params['flag_condition']['sites'].map(&:to_i)
               else
                 @condition.site_ids
               end

    posts = Post.joins(:reasons)
                .group(Arel.sql('posts.id'))
                .where('posts.user_reputation <= ?', @condition.max_poster_rep)
                .where(site_id: site_ids)
                .having('count(reasons.id) >= ?', @condition.min_reason_count)
                .having('sum(reasons.weight) >= ?', @condition.min_weight)

    post_feedback_results = posts.pluck(:is_tp, :is_fp, :is_naa)
    @false_positive_count = post_feedback_results.count do |rec|
      rec[1] || rec[2]
    end
    @true_positive_count = post_feedback_results.count do |rec|
      rec[0]
    end

    @posts = posts.includes(feedbacks: [:user]).order(Arel.sql('posts.id DESC')).paginate(page: params[:page], per_page: 100)
    @sites = Site.where(id: @posts.map(&:site_id)).to_a
  end
end
