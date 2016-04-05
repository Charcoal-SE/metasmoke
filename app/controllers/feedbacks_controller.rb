class FeedbacksController < ApplicationController
  before_filter :authenticate_user!, except: [:create]
  before_action :set_feedback, only: [:show, :edit, :update, :destroy]
  before_filter :check_if_smokedetector, :only => :create

  protect_from_forgery :except => [:create]

  # GET /feedbacks
  # GET /feedbacks.json
  def index
    @feedbacks = Feedback.all
  end

  def clear
    raise ActionController::RoutingError.new('Not Found') if current_user.nil? or not current_user.is_admin?

    @post = Post.includes(:feedbacks).find(params[:id])
    @sites = [@post.site]

    raise ActionController::RoutingError.new('Not Found') if @post.nil?
  end

  def delete
    raise ActionController::RoutingError.new('Not Found') if current_user.nil? or not current_user.is_admin?

    f = Feedback.find params[:id]
    
    f.post.reasons.each do |reason|
      expire_fragment(reason)
    end
    
    f.destroy

    redirect_to clear_post_feedback_path(f.post_id)
  end

  # POST /feedbacks
  # POST /feedbacks.json
  def create
    @feedback = Feedback.new(feedback_params)

    post_link = feedback_params[:post_link]

    post = Post.find_by_link(post_link)

    if post == nil
      render :text => "Error: No post found for link" and return
    end

    post.reasons.each do |reason|
      expire_fragment(reason)
    end
    
    expire_fragment("post" + post.id.to_s)

    @feedback.post = post

    respond_to do |format|
      if @feedback.save
        format.json { render :show, status: :created, :text => "OK" }
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
      params.require(:feedback).permit(:message_link, :user_name, :user_link, :feedback_type, :post_link)
    end
end
