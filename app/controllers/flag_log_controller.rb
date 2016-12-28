class FlagLogController < ApplicationController
  def index
    @flag_logs = FlagLog.all.order('created_at DESC').includes(:post => [:feedbacks => [:user, :api_key]]).includes(:user).paginate(:page => params[:page], :per_page => 100)
    @sites = Site.where(:id => @flag_logs.map(&:post).map(&:site_id)).to_a
  end
end
