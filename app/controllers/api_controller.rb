class ApiController < ApplicationController
  before_action :verify_key
  before_action :set_pagesize

  def posts
    @posts = Post.where(:id => params[:ids].split(";"))
    results = @posts.paginate(:page => params[:page], :per_page => @pagesize)
    has_more = (results.count > @pagesize)
    render :json => { :items => results, :has_more => has_more }
  end

  def post_feedback
    @post = Post.find params[:id]
    render :json => @post.feedbacks.select_without_nil
  end

  def post_reasons
    @post = Post.find params[:id]
    render :json => @post.reasons
  end

  def reasons
    @reasons = Reason.where(:id => params[:ids].split(";"))
    results = @reasons.paginate(:page => params[:page], :per_page => @pagesize)
    has_more = (results.count > @pagesize)
    render :json => { :items => results, :has_more => has_more }
  end

  def reason_posts
    @reason = Reason.find params[:id]
    results = @reason.posts.paginate(:page => params[:page], :per_page => @pagesize)
    has_more = (results.count > @pagesize)
    render :json => { :items => results, :has_more => has_more }
  end

  private
    def verify_key
      unless params[:key].present? && ApiKey.where(:key => params[:key]).count == 1
        render :json => { :error_name => "unauthenticated", :error_code => 403, :error_message => "No key was passed or the passed key is invalid." }
      end
    end

    def set_pagesize
      @pagesize = [params[:per_page] || 10, 100].min
    end
end
