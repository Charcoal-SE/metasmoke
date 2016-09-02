class ApiKeysController < ApplicationController
  before_action :verify_admin
  before_action :set_key, :except => [:index, :new, :create]

  def new
    @key = ApiKey.new
    @key.key = Digest::SHA256.hexdigest("#{rand(0..9e9)}#{Time.now}")
  end

  def create
    @key = ApiKey.new(key_params)
    @key.save!
    flash[:success] = "Successfully registered API key #{@key.key}"
    redirect_to :admin_new_key
  end

  def edit
  end

  def update
    if @key.update key_params
      flash[:success] = "Successfully updated."
      redirect_to url_for(:controller => :api_keys, :action => :index)
    else
      flash[:danger] = "Failed to update."
      render :edit
    end
  end

  def index
    @keys = ApiKey.all
  end

  def revoke_write_tokens
    unless ApiToken.where(:api_key => @key).destroy_all
      flash[:danger] = "Failed to revoke all API write tokens - tokens need to be removed manually."
    else
      flash[:success] = "Successfully removed all write tokens belonging to #{@key.app_name}."
    end
    redirect_to url_for(:controller => :api_keys, :action => :index)
  end

  private
    def key_params
      params.require(:api_key).permit(:key, :app_name, :user_id)
    end

    def set_key
      @key = ApiKey.find params[:id]
    end
end
