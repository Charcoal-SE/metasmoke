# frozen_string_literal: true

class FeedbacksController < ApplicationController
  before_action :authenticate_user!, except: [:create]
  before_action :set_feedback, only: [:show, :edit, :update, :destroy]
  before_action :check_if_smokedetector, only: :create

  protect_from_forgery except: [:create]

  def clear
    @post = Post.find(params[:id])
    @feedbacks = Feedback.unscoped.where(post_id: params[:id])

    unless verify_access(@feedbacks)
      redirect_to missing_privileges_path(required: :admin)
      return
    end

    @sites = [@post.site]

    raise ActionController::RoutingError, 'Not Found' if @post.nil?
  end

  def delete
    f = Feedback.find params[:id]

    raise ActionController::RoutingError, 'Not Found' unless verify_access(f)

    f.post.reasons.each do |reason|
      expire_fragment(reason)
    end

    f.is_invalidated = true
    f.invalidated_by = current_user.id
    f.invalidated_at = DateTime.now
    f.save!

    redirect_to clear_post_feedback_path(f.post_id)
  end

  # POST /feedbacks
  # POST /feedbacks.json
  def create
    # puts Feedback.where(post_id: params[:feedback][:post_id], user_name: params[:feedback][:user_name]).present?
    post_link = feedback_params[:post_link]

    post = Post.where(link: post_link).order(:created_at).last

    render(plain: 'Error: No post found for link') && return if post.nil?

    # Ignore identical feedback from the same user
    if Feedback.where(post: post, user_name: feedback_params[:user_name], feedback_type: feedback_params[:feedback_type]).present?
      render(plain: 'Identical feedback from user already exists on post') && return
    end

    @feedback = Feedback.new(feedback_params)

    post.reasons.each do |reason|
      expire_fragment(reason)
    end

    expire_fragment('post' + post.id.to_s)

    @feedback.post = post

    if Feedback.where(chat_user_id: @feedback.chat_user_id).count == 0
      feedback_intro = 'It seems this is your first time sending feedback to SmokeDetector. ' \
      'Make sure you\'ve read the guidance on [your privileges](https://git.io/voC8N), ' \
      'the [available commands](https://git.io/voC4m), and [what feedback to use in different situations](https://git.io/voC4s).'
      ActionCable.server.broadcast 'smokedetector_messages', message: "@#{@feedback.user_name.delete(' ')}: #{feedback_intro}"
    end

    respond_to do |format|
      if @feedback.save
        format.json { render :show, status: :created, body: 'OK' }
      else
        format.json { render json: @feedback.errors, status: :unprocessable_entity }
      end
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_feedback
    @feedback = Feedback.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def feedback_params
    params.require(:feedback).permit(:message_link, :user_name, :user_link, :feedback_type, :post_link, :chat_user_id, :chat_host)
  end

  def verify_access(feedbacks)
    return true if current_user.has_role? :admin
    if feedbacks.respond_to? :where
      return false unless feedbacks.where(user_id: current_user.id).exists?
    else
      return false unless feedbacks.user_id == current_user.id
    end
    true
  end
end
