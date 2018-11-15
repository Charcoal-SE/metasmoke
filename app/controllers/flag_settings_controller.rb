# frozen_string_literal: true

class FlagSettingsController < ApplicationController
  protect_from_forgery except: [:smokey_disable_flagging, :update_site_settings]
  before_action :set_flag_setting, only: [:edit, :update]
  before_action :verify_admin, except: [:index, :audits, :smokey_disable_flagging, :dashboard, :by_site]
  before_action :authenticate_user!, except: [:index, :audits, :smokey_disable_flagging, :dashboard, :by_site]
  before_action :check_if_smokedetector, only: [:smokey_disable_flagging]

  # GET /flag_settings
  # GET /flag_settings.json
  def index
    @flag_settings = FlagSetting.all
  end

  # GET /flag_settings/new
  def new
    @flag_setting = FlagSetting.new
  end

  # GET /flag_settings/1/edit
  def edit; end

  # POST /flag_settings
  # POST /flag_settings.json
  def create
    @flag_setting = FlagSetting.new(flag_setting_params)

    respond_to do |format|
      if @flag_setting.save
        format.html { redirect_to flag_settings_path, notice: 'Flag setting was successfully created.' }
        format.json { render :show, status: :created, location: @flag_setting }
      else
        format.html { render :new, status: 422 }
        format.json { render json: @flag_setting.errors, status: :unprocessable_entity }
      end
    end
  end

  def audits
    @audits = Audited::Audit.where(auditable_type: 'FlagSetting')
                            .includes(:auditable, :user)
                            .order(Arel.sql('created_at DESC'))
                            .paginate(page: params[:page], per_page: 100)
  end

  # PATCH/PUT /flag_settings/1
  # PATCH/PUT /flag_settings/1.json
  def update
    respond_to do |format|
      if @flag_setting.update(flag_setting_params)

        if %w[min_accuracy min_post_count].include? @flag_setting.name
          # If an accuracy/post count requirement is changed,
          # we want to re-validate all existing FlagConditions
          # and disable them if they aren't in compliance with the
          # new settings
          Thread.new do
            FlagCondition.revalidate_all
          end
        end

        format.html { redirect_to flag_settings_path, notice: 'Flag setting was successfully updated.' }
        format.json { render :show, status: :ok, location: @flag_setting }
      else
        format.html { render :edit, status: 422 }
        format.json { render json: @flag_setting.errors, status: :unprocessable_entity }
      end
    end
  end

  # Used by SmokeDetector's !!/stopflagging
  def smokey_disable_flagging
    # -1 == System user in metasmoke prod
    Audited::Audit.as_user(User.find(-1)) do
      FlagSetting.find_by(name: 'flagging_enabled').update(value: '0')
    end

    SmokeDetector.send_message_to_charcoal('**Autoflagging disabled** through chat.')

    render plain: 'OK'
  end

  def dashboard
    @recent_count = FlagLog.auto.where('created_at > ?', 1.day.ago).where(success: true).count
  end

  def by_site
    if params[:site].present?
      @site = Site.find params[:site]
      @flags = FlagLog.where(site: @site)
      @posts = Post.includes_for_post_row.where(id: @flags.where.not(post_id: nil).map(&:post_id))
                   .paginate(per_page: 50, page: params[:page])
    end
    @sites = Site.mains.order(site_name: :asc)
  end

  def site_settings
    @sites = Site.mains.order(site_name: :asc)
    @json = JSON.dump(@sites.map do |s|
      [s.id, { flags_enabled: s.flags_enabled,
               max_flags: s.max_flags_per_post,
               auto_disputed_flags_enabled: s.auto_disputed_flags_enabled,
               name: s.site_name, domain: s.site_domain }]
    end.to_h)
  end

  def update_site_settings
    updata = params[:data]
    updata.each do |k, v|
      next unless v['changed'].present? && v['changed'] == true
      params = {}
      params[:flags_enabled] = v['flags_enabled'] unless v['flags_enabled'].nil?
      params[:max_flags_per_post] = v['max_flags'] unless v['max_flags'].nil?
      params[:auto_disputed_flags_enabled] = v['auto_disputed_flags_enabled'] unless v['auto_disputed_flags_enabled'].nil?
      site = Site.find(k)
      puts "Update: #{site} #{params}"
      site.update(params)
    end
    head :no_content
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_flag_setting
    @flag_setting = FlagSetting.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def flag_setting_params
    params.require(:flag_setting).permit(:name, :value)
  end
end
