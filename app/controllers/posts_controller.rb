class PostsController < ApplicationController

  protect_from_forgery :except => [:create]
  before_filter :check_if_smokedetector, :only => :create

  def show
    @post = Post.find(params[:id])
  end

  def recentpostsapi
    posts = Rails.cache.fetch("last-posts", :expires_in => 30.seconds) do
      Post.joins(:site).select("posts.title, posts.link, sites.site_logo").order(:created_at).last(100)
    end

    posts = posts.last([params[:size].to_i, 100].min).reverse

    render json: posts, status: 200
  end

  # GET /posts
  # GET /posts.json
  def index
    @posts = Post.all.includes(:reasons).includes(:feedbacks).paginate(:page => params[:page], :per_page => 100).order('created_at DESC')
    @sites = Site.where(:id => @posts.map(&:site_id))
  end

  # POST /posts
  # POST /posts.json
  def create
    @post = Post.new(post_params)

    @post.site = Site.find_by_site_domain(URI.parse(@post.link).host)

    params["post"]["reasons"].each do |r|
      reason = Reason.find_or_create_by(reason_name: r.split("(").first.strip.humanize)

      reason.last_post_title = @post.title
      reason.save!

      @post.reasons << reason
    end

    respond_to do |format|
      if @post.save
        format.json { render status: :created, :text => "OK" }
      else
        format.json { render json: @post.errors, status: :unprocessable_entity }
      end
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_post
      @post = Post.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def post_params
      params.require(:post).permit(:title, :body, :link, :post_creation_date, :reasons, :username, :user_link)
    end
end
