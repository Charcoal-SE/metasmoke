# frozen_string_literal: true

class PostCommentsController < ApplicationController
  before_action :verify_reviewer
  before_action :set_comment, except: [:create]
  before_action :verify_access, except: [:create]
  skip_before_action :verify_authenticity_token, only: [:update]

  def create
    @comment = PostComment.new comment_params.merge(user: current_user)
    flash[:danger] = 'Failed to post your comment.' unless @comment.save
    redirect_back fallback_location: post_path(@comment.post_id)
  end

  def update
    unless @comment.update(text: params[:text])
      flash[:danger] = 'Failed to update your comment.'
    end
    redirect_back fallback_location: post_path(@comment.post_id)
  end

  def destroy
    post_id = @comment.post_id
    if @comment.destroy
      flash[:success] = 'Comment removed.'
    else
      flash[:danger] = 'Failed to remove your comment.'
    end
    redirect_to post_path(post_id)
  end

  def text
    render json: { text: @comment.text }
  end

  private

  def comment_params
    params.require(:post_comment).permit(:post_id, :text)
  end

  def set_comment
    @comment = PostComment.find params[:id]
  end

  def verify_access
    return if current_user == @comment.user || current_user.has_role?(:admin)
    not_found
  end
end
