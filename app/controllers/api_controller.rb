class ApiController < ApplicationController
  before_action :verify_key
  before_action :set_pagesize
  before_action :verify_auth, :only => [:create_feedback]
  skip_before_action :verify_authenticity_token, :only => [:create_feedback]

  def posts
    @posts = Post.where(:id => params[:ids].split(";"))
    results = @posts.paginate(:page => params[:page], :per_page => @pagesize)
    render :json => { :items => results, :has_more => has_more?(params[:page], results.count) }
  end

  def posts_by_feedback
    @posts = Post.all.joins(:feedbacks).where(:feedbacks => { :feedback_type => params[:type] })
    results = @posts.paginate(:page => params[:page], :per_page => @pagesize)
    render :json => { :items => results, :has_more => has_more?(params[:page], results.count) }
  end

  def posts_by_url
    @post = Post.where(:link => params[:url])
    render :json => @post
  end

  def post_feedback
    @post = Post.find params[:id]
    render :json => @post.feedbacks
  end

  def post_reasons
    @post = Post.find params[:id]
    render :json => @post.reasons
  end

  def reasons
    @reasons = Reason.where(:id => params[:ids].split(";"))
    results = @reasons.paginate(:page => params[:page], :per_page => @pagesize)
    render :json => { :items => results, :has_more => has_more?(params[:page], results.count) }
  end

  def reason_posts
    @reason = Reason.find params[:id]
    results = @reason.posts.paginate(:page => params[:page], :per_page => @pagesize)
    render :json => { :items => results, :has_more => has_more?(params[:page], results.count) }
  end

  def create_feedback
    @post = Post.find params[:id]
    @feedback = Feedback.new(:user => current_user, :post => @post)
    @feedback.feedback_type = params[:type]
    if @feedback.save
      # ActionCable.server.broadcast "smokedetector_messages", { :message => "Received feedback (#{params[:type]}) from #{current_user.username} on #{@post.id} via API application #{@key.app_name}." }
      render :json => @post.feedbacks, :status => 201
    else
      render :status => 500, :json => { :error_name => "failed", :error_code => 500, :error_message => "Feedback object failed to save." }
    end
  end

  private
    def verify_key
      @key = ApiKey.find_by_key(params[:key])
      unless params[:key].present? && @key.present?
        render :status => 403, :json => { :error_name => "unauthenticated", :error_code => 403, :error_message => "No key was passed or the passed key is invalid." } and return
      end
    end

    def verify_auth
      unless user_signed_in?
        render :status => 401, :json => { :error_name => "unauthorized", :error_code => 401, :error_message => "There must be a metasmoke user logged in to use this route." } and return
      end
    end

    def set_pagesize
      @pagesize = [params[:per_page] || 10, 100].min
    end

    def has_more?(page, result_count)
      (page || 1) * @pagesize < result_count
    end
end
