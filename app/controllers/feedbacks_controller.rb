class FeedbacksController < ApplicationController
  before_action :authenticate_user!, except: [:create]
  before_action :verify_admin, only: [:clear, :delete]
  before_action :set_feedback, only: [:show, :edit, :update, :destroy]
  before_action :check_if_smokedetector, :only => :create

  protect_from_forgery :except => [:create]

  # GET /feedbacks
  # GET /feedbacks.json
  def index
    @feedbacks = Feedback.all
  end

  def clear
    @post = Post.find(params[:id])
    @feedbacks = Feedback.unscoped.where(:post_id => params[:id])
    @sites = [@post.site]

    raise ActionController::RoutingError.new('Not Found') if @post.nil?
  end

  def delete
    f = Feedback.find params[:id]

    f.post.reasons.each do |reason|
      expire_fragment(reason)
    end

    f.is_invalidated = true
    f.invalidated_by = current_user.id
    f.invalidated_at = DateTime.now
    f.save

    if f.user
      total_count = Feedback.unscoped.where(:user => f.user).count
      invalid_count = Feedback.unscoped.where(:user => f.user, :is_invalidated => true).count
      mode = 'user'
    else
      total_count = Feedback.unscoped.where(:user_name => f.user_name).count
      invalid_count = Feedback.unscoped.where(:user_name => f.user_name, :is_invalidated => true).count
      mode = 'user_name'
    end
    if invalid_count > (0.04 * total_count) + 4
      ignored = nil
      if mode == 'user'
        ignored = IgnoredUser.find_or_create_by(:user_id => f.user.id)
      elsif mode == 'user_name'
        ignored = IgnoredUser.find_or_create_by(:user_name => f.user_name)
      end
      ignored.is_ignored = true
      ignored.save
    end

    redirect_to clear_post_feedback_path(f.post_id)
  end

  # POST /feedbacks
  # POST /feedbacks.json
  def create
    @feedback = Feedback.new(feedback_params)

    @ignored = IgnoredUser.find_by_user_name(@feedback.user_name)
    total_count = Feedback.unscoped.where(:user_name => @feedback.user_name).count
    invalid_count = Feedback.unscoped.where(:user_name => @feedback.user_name, :is_invalidated => true).count
    if invalid_count > (0.04 * total_count) + 4
      if @ignored && @ignored.is_ignored == true
        return
      end
    else
      if @ignored
        @ignored.is_ignored = false
        @ignored.save
      end
    end

    post_link = feedback_params[:post_link]

    post = Post.where(:link => post_link).order(:created_at).last

    if post == nil
      render :text => "Error: No post found for link" and return
    end

    post.reasons.each do |reason|
      expire_fragment(reason)
    end

    expire_fragment("post" + post.id.to_s)

    @feedback.post = post

    if Feedback.where(:chat_user_id => @feedback.chat_user_id).count == 0
      ActionCable.server.broadcast "smokedetector_messages", { message: "@#{@feedback.user_name}: It seems this is your first time feeding back to SmokeDetector. Make sure you've read the guidance on [your privileges](https://github.com/Charcoal-SE/SmokeDetector/wiki/Privileges), the [available commands](https://github.com/Charcoal-SE/SmokeDetector/wiki/Commands), and [how to feed back](https://github.com/Charcoal-SE/SmokeDetector/wiki/Feedback-Guidance)." }
    end

    respond_to do |format|
      if @feedback.save
        format.json { render :show, status: :created, :body => "OK" }
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
      params.require(:feedback).permit(:message_link, :user_name, :user_link, :feedback_type, :post_link, :chat_user_id)
    end
end
