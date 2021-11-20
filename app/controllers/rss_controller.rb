# frozen_string_literal: true

class RSSController < ApplicationController
  def deleted
    # Wait 10 minutes to see if it's been deleted
    @posts = Post.all
    @posts = @posts.where('created_at < ?', 10.minutes.ago) unless params[:nowait]
    @posts = @posts.order('created_at DESC').paginate(page: params[:page], per_page: 50)
    @posts = @posts.where(site: params[:site]) if params[:site].present?

    @tags = []

    # If 'deleted' is passed, check if 'true'. If it's not passed, treat it as true.
    @posts = if params[:deleted].present?
               case params[:deleted].downcase
               when 'true'
                 @posts.where.not(deleted_at: nil)
               when 'any'
                 @posts
               else
                 @posts.where(deleted_at: nil)
               end
             else
               @posts.where.not(deleted_at: nil)
             end

    # If 'autoflagged' is passed, check if 'true'. If it's not passed, treat it as true.
    @posts = if params[:autoflagged].present?
               case params[:autoflagged].downcase
               when 'true'
                 @posts.where(autoflagged: params[:autoflagged])
               when 'any'
                 @posts
               else
                 @posts.where(autoflagged: true)
               end
             else
               @posts.where(autoflagged: true)
             end

    if params[:from_date].present?
      @posts = @posts.where('`posts`.`created_at` > ?',
                            DateTime.strptime(params[:from_date], '%s'))
    end
    if params[:to_date].present?
      @posts = @posts.where('`posts`.`created_at` < ?',
                            DateTime.strptime(params[:to_date], '%s'))
    end
    @posts = @posts.includes(:feedbacks).where(feedbacks: { feedback_type: params[:feedback_type] }) if params[:feedback_type].present?
    respond_to do |format|
      format.html
      format.rss { render layout: false }
      format.xml { render 'deleted.rss', layout: false }
    end
  end
end
