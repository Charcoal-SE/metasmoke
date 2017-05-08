class FlagSettingsController < ApplicationController
  protect_from_forgery except: [:smokey_disable_flagging]
  before_action :set_flag_setting, only: [:edit, :update]
  before_action :verify_admin, except: [:index, :audits, :smokey_disable_flagging, :dashboard]
  before_action :authenticate_user!, except: [:index, :audits, :smokey_disable_flagging, :dashboard]
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
  def edit
  end

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
    @audits = Audited::Audit.where(auditable_type: "FlagSetting").includes(:auditable, :user).order('created_at DESC').paginate(page: params[:page], per_page: 100)
  end

  # PATCH/PUT /flag_settings/1
  # PATCH/PUT /flag_settings/1.json
  def update
    respond_to do |format|
      if @flag_setting.update(flag_setting_params)

        if ["min_accuracy", "min_post_count"].include? @flag_setting.name
          # If an accuracy/post count requirement is changed,
          # we want to re-validate all existing FlagConditions
          # and disable them if they aren't in compliance with the
          # new settings
          Thread.new do
            FlagCondition.revalidate_all
          end
        end

        AutoflaggingMailer.setting_changed(@flag_setting, current_user).deliver_now
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
      FlagSetting.find_by_name("flagging_enabled").update(value: "0")
    end

    SmokeDetector.send_message_to_charcoal("**Autoflagging disabled** through chat.")

    render plain: "OK"
  end

  def dashboard
    @recent_count = FlagLog.auto.where('created_at > ?', 1.day.ago).where(success: true).count
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
