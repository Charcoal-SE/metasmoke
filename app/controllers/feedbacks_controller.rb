class FeedbacksController < ApplicationController
  before_action :authenticate_user!, except: [:create]
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

    raise ActionController::RoutingError.new('Not Found') unless verify_access(@feedbacks)

    @sites = [@post.site]

    raise ActionController::RoutingError.new('Not Found') if @post.nil?
  end

  def delete
    f = Feedback.find params[:id]

    raise ActionController::RoutingError.new('Not Found') unless verify_access(f)

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
    # puts Feedback.where(:post_id => params[:feedback][:post_id], :user_name => params[:feedback][:user_name]).present?
    post_link = feedback_params[:post_link]

    post = Post.where(:link => post_link).order(:created_at).last

    if post == nil
      render plain: "Error: No post found for link" and return
    end

    # Ignore identical feedback from the same user
    if Feedback.where(:post => post, :user_name => feedback_params[:user_name], :feedback_type => feedback_params[:feedback_type]).present?
      render plain: "Identical feedback from user already exists on post" and return
    end

    @feedback = Feedback.new(feedback_params)

    @ignored = IgnoredUser.find_by_user_name(@feedback.user_name)
    total_count = Feedback.unscoped.where(:user_name => @feedback.user_name).count
    invalid_count = Feedback.invalid.where(:user_name => @feedback.user_name).count
    if invalid_count > (0.04 * total_count) + 4
      if @ignored && @ignored.is_ignored == true
        @feedback.is_ignored = true
      end
    else
      if @ignored
        @ignored.destroy!
      end
    end

    post.reasons.each do |reason|
      expire_fragment(reason)
    end

    expire_fragment("post" + post.id.to_s)

    @feedback.post = post

    unless @feedback.is_ignored
      previous_identical = Feedback.ignored.where(:post => @feedback.post, :feedback_type => @feedback.feedback_type)
      previous_identical.update_all(:is_ignored => false)

      opposite_type = @feedback.feedback_type == 'tpu-' ? 'fp-' : 'tpu-'
      previous_opposite = Feedback.ignored.where(:post => @feedback.post, :feedback_type => opposite_type)
      previous_opposite.update_all(:is_invalidated => true, :is_ignored => false, :invalidated_at => Time.now, :invalidated_by => -1)
    end

    if Feedback.where(:chat_user_id => @feedback.chat_user_id).count == 0
      ActionCable.server.broadcast "smokedetector_messages", { message: "@#{@feedback.user_name.gsub(" ", "")}: It seems this is your first time sending feedback to SmokeDetector. Make sure you've read the guidance on [your privileges](https://git.io/voC8N), the [available commands](https://git.io/voC4m), and [what feedback to use in different situations](https://git.io/voC4s)." }
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
      params.require(:feedback).permit(:message_link, :user_name, :user_link, :feedback_type, :post_link, :chat_user_id, :chat_host)
    end

    def verify_access(feedbacks)
      return true if current_user.has_role? :admin
      if feedbacks.respond_to? :where
        unless feedbacks.where(:user_id => current_user.id).exists?
          return false
        end
      else
        unless feedbacks.user_id == current_user.id
          return false
        end
      end
      return true
    end
end
