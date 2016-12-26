class FlagLogController < ApplicationController
  def index
    @flag_logs = FlagLog.all.order('created_at DESC').includes(:post, :user).paginate(:page => params[:page], :per_page => 100)
  end
end
