class BlacklistController < ApplicationController
  before_action :verify_code_admin, :except => [:index]

  def index
    @websites = BlacklistedWebsite.all.paginate(:per_page => 100, :page => params[:page])
  end

  def add_website

  end

  def create_website

  end

  def deactivate_website

  end
end
