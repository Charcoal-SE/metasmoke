# frozen_string_literal: true

class SpamDomainsController < ApplicationController
  before_action :check_if_smokedetector, only: [:create]
  before_action :authenticate_user!, only: [:edit, :update, :destroy]
  before_action :verify_core, only: [:edit, :update]
  before_action :verify_admin, only: [:destroy]
  before_action :set_spam_domain, only: [:show, :edit, :update, :destroy]

  def index
    @total = SpamDomain.count
    @domains = if params[:filter].present?
                 SpamDomain.where('domain LIKE ?', "%#{params[:filter]}%")
               else
                 SpamDomain.all
               end.order(domain: :asc).paginate(page: params[:page], per_page: 100)
    @counts = {
      all: @domains.joins(:posts).group('spam_domains.id').count,
      tp: @domains.joins(:posts).where(posts: { is_tp: true }).group('spam_domains.id').count,
      fp: @domains.joins(:posts).where(posts: { is_fp: true }).group('spam_domains.id').count,
      naa: @domains.joins(:posts).where(posts: { is_naa: true }).group('spam_domains.id').count
    }
  end

  def create
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

  def update
    if @domain.update domain_params
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

  private

  def set_spam_domain
    @domain = SpamDomain.find params[:id]
  end

  def domain_params
    params.require(:spam_domain).permit(:whois)
  end
end
