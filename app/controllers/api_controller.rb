class ApiController < ApplicationController
  before_action :verify_key
  before_action :set_pagesize
  before_action :verify_write_token, :only => [:create_feedback]
  skip_before_action :verify_authenticity_token, :only => [:create_feedback]

  def posts
    @posts = Post.where(:id => params[:ids].split(";")).order(:id => :desc)
    results = @posts.paginate(:page => params[:page], :per_page => @pagesize)
    render :json => { :items => results, :has_more => has_more?(params[:page], results.count) }
  end

  def posts_by_feedback
    @posts = Post.all.joins(:feedbacks).where(:feedbacks => { :feedback_type => params[:type] }).order(:id => :desc)
    results = @posts.paginate(:page => params[:page], :per_page => @pagesize)
    render :json => { :items => results, :has_more => has_more?(params[:page], results.count) }
  end

  def posts_by_url
    @post = Post.where(:link => params[:url]).order(:id => :desc)
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
    @reasons = Reason.where(:id => params[:ids].split(";")).order(:id => :desc)
    results = @reasons.paginate(:page => params[:page], :per_page => @pagesize)
    render :json => { :items => results, :has_more => has_more?(params[:page], results.count) }
  end

  def reason_posts
    @reason = Reason.find params[:id]
    results = @reason.posts.order(:id => :desc).paginate(:page => params[:page], :per_page => @pagesize)
    render :json => { :items => results, :has_more => has_more?(params[:page], results.count) }
  end

  def undeleted_posts
    @posts = Post.includes(:deletion_logs).where(:is_tp => true, :deletion_logs => { :is_deleted => true })
    results = @posts.order(:id => :desc).paginate(:page => params[:page], :per_page => @pagesize)
    render :json => { :items => results, :has_more => has_more?(params[:page], results.count) }
  end

  def create_feedback
    @post = Post.find params[:id]
    @feedback = Feedback.new(:user => @user, :post => @post, :api_key => @key)
    @feedback.feedback_type = params[:type]
    if @feedback.save
      if @feedback.is_positive?
        begin
          ActionCable.server.broadcast "smokedetector_messages", { blacklist: { uid: @post.stack_exchange_user.user_id.to_s, site: URI.parse(@post.stack_exchange_user.site.site_url).host, post: @post.link } }
        rescue
        end
      elsif @feedback.is_naa?
        begin
          ActionCable.server.broadcast "smokedetector_messages", { naa: { post_link: @post.link } }
        rescue
        end
      end
      unless Feedback.where(:post_id => @post.id, :feedback_type => @feedback.feedback_type).where.not(:id => @feedback.id).exists?
        ActionCable.server.broadcast "smokedetector_messages", { message: "#{@feedback.feedback_type} by #{@user.username}" + (@post.id == Post.last.id ? "" : " on [#{@post.title}](#{@post.link})") }
      end
      render :json => @post.feedbacks, :status => 201
    else
      render :status => 500, :json => { :error_name => "failed", :error_code => 500, :error_message => "Feedback object failed to save." }
    end
  end

  private
    def verify_key
      @key = ApiKey.find_by_key(params[:key])
      unless params[:key].present? && @key.present?
        smokey = SmokeDetector.find_by_access_token(params[:key])
        unless smokey.present?
          render :status => 403, :json => { :error_name => "unauthenticated", :error_code => 403, :error_message => "No key was passed or the passed key is invalid." } and return
        end
      end
    end

    def set_pagesize
      @pagesize = [params[:per_page].to_i || 10, 100].min
    end

    def has_more?(page, result_count)
      (page || 1) * @pagesize < result_count
    end

    def verify_write_token
      # This method deliberately doesn't check expiry: tokens are valid for authorization forever, but can only be fetched using the code in the first 10 minutes.
      @token = ApiToken.where(:token => params[:token], :api_key => @key)
      if @token.any?
        @token = @token.first
        @user = @token.user
      else
        render :status => 401, :json => { :error_name => 'unauthorized', :error_code => 401, :error_message => "The token provided does not supply authorization to perform this action." } and return
      end
    end
end
