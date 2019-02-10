# frozen_string_literal: true

class DeletionLogsController < ApplicationController
  before_action :set_deletion_log, only: %i[show edit update destroy]
  before_action :check_if_smokedetector, only: :create
  protect_from_forgery except: [:create]

  # POST /deletion_logs
  # POST /deletion_logs.json
  def create
    post_link = deletion_log_params[:post_link]

    post = Post.find_by(link: post_link)

    if post.nil?
      render plain: 'Error: No post found for link', status: 404
      return
    elsif post.deletion_logs.where(is_deleted: params[:deletion_log][:is_deleted])
              .where('uncertainty <= ?', params[:deletion_log][:uncertainty]).exists?
      render plain: 'Error: Deletion logs already exist', status: 409
      return
    end

    @deletion_log = post.deletion_logs.new
    @deletion_log.is_deleted = params[:deletion_log][:is_deleted]
    @deletion_log.uncertainty = params[:deletion_log][:uncertainty]

    respond_to do |format|
      if @deletion_log.save
        format.json { render plain: 'OK', status: :created }
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
