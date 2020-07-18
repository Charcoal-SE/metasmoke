# frozen_string_literal: true

class DomainTagsController < ApplicationController
  before_action :authenticate_user!, only: %i[add remove edit update destroy add_post remove_post submit_mass_tag add_review]
  before_action :verify_core, only: %i[add remove edit update add_post remove_post submit_mass_tag add_review]
  before_action :verify_admin, only: [:destroy]
  before_action :set_domain_tag, only: %i[show edit update destroy]
  before_action :verify_developer, only: [:merge]

  def index
    @tags = if params[:filter].present? && params[:include_special].present?
              DomainTag.all.where('name LIKE ?', "%#{params[:filter]}%")
            elsif params[:filter].present?
              DomainTag.standard.where('name LIKE ?', "%#{params[:filter]}%")
            else
              DomainTag.standard
            end.order(name: :asc).paginate(page: params[:page], per_page: 100)
    @counts = DomainTag.where(id: @tags.map(&:id)).joins(:spam_domains).group(Arel.sql('domain_tags.id')).count
  end

  def add
    @tag = DomainTag.find_or_create_by name: params[:tag_name]
    @domain = SpamDomain.find params[:domain_id]
    if @domain.domain_tags.include? @tag
      flash[:danger] = "This domain already has the tag '#{@tag.name}'."
    else
      @domain.domain_tags << @tag
    end
    redirect_to spam_domain_path(@domain)
  end

  def add_review
    @tag = DomainTag.find_or_create_by name: params[:tag_name]
    @domain = SpamDomain.find params[:domain_id]
    @domain.domain_tags << @tag unless @domain.domain_tags.include? @tag
    render 'domain_tags/_tag', locals: { tag: @tag, domain: @domain }, layout: nil
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
      @counts_summary = %i[all tp fp naa].map do |t|
        [t, Post.joins(spam_domains: :domain_tags).where(domain_tags: { id: @tag.id }).distinct.send(t).count]
      end.to_h
      @domains = @tag.spam_domains.paginate(page: params[:page], per_page: 100)
      @counts = SpamDomain.where(id: @domains.map(&:id)).joins(:posts).group(Arel.sql('spam_domains.id')).count
      @counts_per_domain = %i[tp fp naa].map do |t|
        [t, @tag.spam_domains.joins(:posts).where(posts: { "is_#{t}": true }).group('spam_domains.id').count]
      end.to_h
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

  def merge
    source = DomainTag.find params[:source_id]
    target = DomainTag.find params[:target_id]

    source.merge_into target

    flash[:success] = 'Tag merge completed.'
    redirect_to domain_tag_path(target)
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
