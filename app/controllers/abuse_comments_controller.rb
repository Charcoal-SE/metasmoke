# frozen_string_literal: true

class AbuseCommentsController < ApplicationController
  before_action :verify_core
  before_action :set_comment, except: [:create]
  before_action :verify_access, except: [:create]
  skip_before_action :verify_authenticity_token, only: [:update]

  def create
    @comment = AbuseComment.new comment_params.merge(user: current_user)
    @comment.text = @comment.text.gsub(/#(\d+)/, '[#\1](https://metasmoke.erwaysoftware.com/abuse/reports/\1)')
    flash[:danger] = 'Failed to post your comment.' unless @comment.save
    redirect_to abuse_report_path(@comment.abuse_report_id)
  end

  def update
    unless @comment.update(text: params[:text])
      flash[:danger] = 'Failed to update your comment.'
    end
    redirect_to abuse_report_path(@comment.abuse_report_id)
  end

  def destroy
    report_id = @comment.abuse_report_id
    if @comment.destroy
      flash[:success] = 'Comment removed.'
    else
      flash[:danger] = 'Failed to remove your comment.'
    end
    redirect_to abuse_report_path(report_id)
  end

  def text
    render json: { text: @comment.text }
  end

  private

  def comment_params
    params.require(:abuse_comment).permit(:abuse_report_id, :text)
  end

  def set_comment
    @comment = AbuseComment.find params[:id]
  end

  def verify_access
    return if current_user == @comment.user || current_user.has_role?(:admin)
    not_found
  end
end
