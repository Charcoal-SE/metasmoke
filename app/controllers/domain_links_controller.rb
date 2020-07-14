# frozen_string_literal: true

class DomainLinksController < ApplicationController
  before_action :verify_core
  before_action :set_link, except: :create
  before_action :verify_admin, only: :destroy

  def create
    @link = DomainLink.new link_params.merge(creator: current_user)
    if @link.save
      Rails.cache.delete :domain_link_types
      render partial: 'domain_links/link', locals: { link: @link, domain: @link.left }
    else
      render json: { success: false }, status: 500
    end
  end

  def update
    if @link.update link_params
      render partial: 'domain_links/link', locals: { link: @link, domain: @link.left }
    else
      render json: { success: false }, status: 500
    end
  end

  def destroy
    if @link.destroy
      redirect_back fallback_location: root_path
    else
      flash[:danger] = 'Failed to remove link.'
      redirect_back fallback_location: @link.left
    end
  end

  private

  def link_params
    params.require(:domain_link).permit(:left_id, :right_id, :comments, :link_type)
  end

  def set_link
    @link = DomainLink.find params[:id]
  end
end
