# frozen_string_literal: true

class DomainTagsController < ApplicationController
  before_action :authenticate_user!, only: [:add, :remove, :edit, :update, :destroy, :add_post, :remove_post]
  before_action :verify_core, only: [:add, :remove, :edit, :update, :add_post, :remove_post]
  before_action :verify_admin, only: [:destroy]
  before_action :set_domain_tag, only: [:show, :edit, :update, :destroy]

  def index
    @tags = if params[:filter].present?
              DomainTag.where('name LIKE ?', "%#{params[:filter]}%")
            else
              DomainTag.all
            end.order(name: :asc).paginate(page: params[:page], per_page: 100)
    @counts = DomainTag.where(id: @tags.map(&:id)).joins(:spam_domains).group(Arel.sql('domain_tags.id')).count
  end

  def add
    @domain = SpamDomain.find params[:domain_id]
    @domain.domain_tags = params[:tag_name].map do |tag_name|
      DomainTag.find_or_create_by name: tag_name
    end
    @domain.save
    redirect_to spam_domain_path(@domain)
  end

  def add_review
    @domain = SpamDomain.find params[:domain_id]
    @domain.domain_tags = params[:tag_name].map do |tag_name|
      dt = DomainTag.find_or_create_by name: tag_name
      @domain.domain_tags.map(&:id).include?(dt.id) ? nil : dt
    end.reject(&:nil?)
    if @domain.save
      render json: { status: 200, message: "Successfully updated tags" }, status: 200
    else
      render text: "Failed to update tags", status: 500
    end
  end

  def add_post
    @tag = DomainTag.find_or_create_by name: params[:tag_name]
    @post = Post.find params[:post_id]
    if @post.post_tags.include? @tag
      flash[:danger] = "This post already has the tag '#{@tag.name}'."
    else
      @post.post_tags << @tag
    end
    redirect_to post_path(@post)
  end

  def remove
    @domain = SpamDomain.find params[:domain_id]
    @domain.domain_tags.delete(DomainTag.find_by(name: params[:tag_name]))
    redirect_to spam_domain_path(@domain)
  end

  def remove_post
    @post = Post.find params[:post_id]
    @post.post_tags.delete(DomainTag.find_by(name: params[:tag_name]))
    redirect_back fallback_location: post_path(@post)
  end

  def show
    if params[:what] == 'posts'
      @posts = @tag.posts.includes_for_post_row.paginate(page: params[:page], per_page: 100)
      @sites = Site.where(id: @posts.map(&:site_id))
    else
      @domains = @tag.spam_domains.paginate(page: params[:page], per_page: 100)
      @counts = SpamDomain.where(id: @domains.map(&:id)).joins(:posts).group(Arel.sql('spam_domains.id')).count
    end
  end

  def edit; end

  def update
    if @tag.update tag_params
      flash[:success] = 'Updated tag.'
      redirect_to domain_tag_path(@tag)
    else
      flash[:danger] = 'Failed to update tag.'
      render :edit
    end
  end

  def destroy
    if @tag.destroy
      flash[:success] = 'Removed tag.'
      redirect_to domain_tags_path
    else
      flash[:danger] = 'Failed to remove tag.'
      render :show
    end
  end

  def mass_tagging
    @domains = if params[:filter].present?
                 mass_tag_filter params[:filter]
               else
                 SpamDomain.all
               end.paginate(page: params[:page], per_page: 100)
    @counts = SpamDomain.where(id: @domains.map(&:id)).joins(:posts).group(Arel.sql('spam_domains.id')).count
    @taggable = params[:filter].present?
  end

  def submit_mass_tag
    @domains = mass_tag_filter params[:filter]
    @tag = DomainTag.find_or_create_by name: params[:tag]
    pairs = @domains.map { |d| [@tag, d] }
    ApplicationRecord.mass_habtm 'domain_tags_spam_domains', 'domain_tag', 'spam_domain', pairs
    flash[:success] = 'Tag applied to selected posts.'
    redirect_to domain_tags_mass_tagging_path(filter: params[:filter])
  end

  private

  def set_domain_tag
    @tag = DomainTag.find params[:id]
  end

  def tag_params
    params.require(:domain_tag).permit(:name, :description)
  end

  def mass_tag_filter(filter_param)
    SpamDomain.where("domain LIKE '#{ApplicationRecord.sanitize_like(filter_param).tr('*', '%')}'")
  end
end
