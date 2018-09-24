# frozen_string_literal: true

class SpamDomainsController < ApplicationController
  before_action :check_if_smokedetector, only: [:create_from_post]
  before_action :authenticate_user!, only: [:edit, :update, :destroy, :create, :new]
  before_action :verify_core, only: [:edit, :update, :create, :new]
  before_action :verify_admin, only: [:destroy]
  before_action :set_spam_domain, only: [:show, :edit, :update, :destroy]

  def index
    @total = SpamDomain.count
    @domains = if params[:filter].present?
                 SpamDomain.where('domain LIKE ?', "%#{params[:filter]}%")
               else
                 SpamDomain.all
               end.includes(:domain_tags).order(domain: :asc).paginate(page: params[:page], per_page: 100)
    SpamDomain.preload_post_counts(@domains)
  end

  def create_from_post
    @post = Post.find params[:post_id]
    domains = params[:domains]
    domains.each do |d|
      record = SpamDomain.find_or_create_by domain: d
      @post.spam_domains << record
    end

    render json: { status: 'success', total_domains: @post.spam_domains.count }
  end

  def show
    @counts = { all: SpamDomain.where(id: params[:id]).joins(:posts).count,
                tp: SpamDomain.where(id: params[:id]).joins(:posts).where(posts: { is_tp: true }).count }
    @posts = @domain.posts.order(created_at: :desc).includes_for_post_row.paginate(page: params[:page], per_page: 100)
    @sites = Site.where(id: @posts.map(&:site_id))
  end

  def edit; end

  def new
    @domain = SpamDomain.new
  end

  def create
    @domain = SpamDomain.new domain_params
    @domain.save

    redirect_to action: :show, id: @domain.id
  end

  def update
    if @domain.update(domain_params.tap { |d| d.delete(:domain) })
      flash[:success] = 'Updated successfully.'
      redirect_to spam_domain_path(@domain)
    else
      flash[:danger] = 'Failed to update.'
      render :edit
    end
  end

  def destroy
    if @domain.destroy
      flash[:success] = 'Removed domain.'
      redirect_to spam_domains_path
    else
      flash[:danger] = 'Failed to remove domain.'
      render :show
    end
  end

  def query
    render json: SpamDomain.where('domain LIKE ?', "%#{params[:q]}%").map { |d| { value: d.id, text: d.domain } }
  end

  private

  def set_spam_domain
    @domain = SpamDomain.find params[:id]
  end

  def domain_params
    params.require(:spam_domain).permit(:whois, :domain)
  end
end
