class ApiController < ApplicationController
  before_action :verify_key
  before_action :set_pagesize
  before_action :verify_write_token, :only => [:create_feedback]
  skip_before_action :verify_authenticity_token, :only => [:create_feedback]

  # Read routes: Posts

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

  def posts_by_site
    @posts = Post.joins('inner join sites on posts.site_id = sites.id').where(:sites => { :site_domain => params[:site] })
    results = @posts.order(:id => :desc).paginate(:page => params[:page], :per_page => @pagesize)
    render :json => { :items => results, :has_more => has_more?(params[:page], results.count) }
  end

  def posts_by_daterange
    @posts = Post.where(:created_at => DateTime.strptime(params[:from_date], '%s')..DateTime.strptime(params[:to_date], '%s'))
    results = @posts.order(:id => :desc).paginate(:page => params[:page], :per_page => @pagesize)
    render :json => { :items => results, :has_more => has_more?(params[:page], results.count) }
  end

  def undeleted_posts
    @posts = Post.left_outer_joins(:deletion_logs).where(:deletion_logs => { :id => nil })
    results = @posts.order(:id => :desc).paginate(:page => params[:page], :per_page => @pagesize)
    render :json => { :items => results, :has_more => has_more?(params[:page], results.count) }
  end

  def post_feedback
    @post = Post.find params[:id]
    render :json => @post.feedbacks
  end

  def post_reasons
    @post = Post.find params[:id]
    render :json => @post.reasons
  end

  def post_valid_feedback
    @post = Post.find params[:id]
    render :formats => :json
  end

  def search_posts
    @posts = Post.all
    if params[:feedback_type].present?
      @posts = @posts.includes(:feedbacks).where(:feedbacks => { :feedback_type => params[:feedback_type] })
    end
    if params[:site].present?
      @posts = @posts.joins('inner join sites on posts.site_id = sites.id').where(:sites => { :site_domain => params[:site] })
    end
    if params[:from_date].present?
      @posts = @posts.where('created_at > ?', DateTime.strptime(params[:from_date], '%s'))
    end
    if params[:to_date].present?
      @posts = @posts.where('created_at < ?', DateTime.strptime(params[:to_date], '%s'))
    end
    results = @posts.order(:id => :desc).paginate(:page => params[:page], :per_page => @pagesize)
    render :json => { :items => results, :has_more => has_more?(params[:page], results.count) }
  end

  # Read routes: Reasons

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

  # Read routes: BlacklistedWebsites

  def blacklisted_websites
    @websites = BlacklistedWebsite.active
    results = @websites.order(:id => :desc).paginate(:page => params[:page], :per_page => @pagesize)
    render :json => { :items => results, :has_more => has_more?(params[:page], results.count) }
  end

  # Read routes: Users

  def users_with_code_privs
    chat_ids = User.code_admins.pluck(:stackexchange_chat_id, :stackoverflow_chat_id, :meta_stackexchange_chat_id)

    items = {}
    ["stackexchange_chat_ids", "stackoverflow_chat_ids", "meta_stackexchange_chat_ids"].each_with_index do |name, index|
      items[name] = chat_ids.map { |a| a[index] }.select { |n| n.present? }
    end

    render :json => { :items => items }
  end

  # Write routes

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
      @pagesize = [(params[:per_page] || 10).to_i, 100].min
    end

    def has_more?(page, result_count)
      (page || 1).to_i * @pagesize < result_count
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
