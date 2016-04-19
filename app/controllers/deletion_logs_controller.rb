class DeletionLogsController < ApplicationController
  before_action :set_deletion_log, only: [:show, :edit, :update, :destroy]
  before_action :check_if_smokedetector, :only => :create
  protect_from_forgery :except => [:create]

  # POST /deletion_logs
  # POST /deletion_logs.json
  def create
    post_link = deletion_log_params[:post_link]

    post = Post.find_by_link(post_link)

    if post == nil
      render :text => "Error: No post found for link" and return
    end

    @deletion_log = post.deletion_logs.new

    @deletion_log.is_deleted = params[:is_deleted]

    respond_to do |format|
      if @deletion_log.save
        format.json { render :plain => "OK", status: :created }
      else
        format.json { render json: @deletion_log.errors, status: :unprocessable_entity }
      end
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_deletion_log
      @deletion_log = DeletionLog.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def deletion_log_params
      params.require(:deletion_log).permit(:post_link, :is_deleted)
    end
end
