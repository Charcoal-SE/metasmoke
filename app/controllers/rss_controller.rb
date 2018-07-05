# frozen_string_literal: true

class RSSController < ApplicationController
  def deleted
    # Wait 10 minutes to see if it's been deleted
    @posts = Post.all
    @posts = @posts.where('created_at < ?', 10.minutes.ago) unless params[:nowait]
    @posts = @posts.order('created_at DESC').paginate(page: params[:page], per_page: 50)
    @posts = @posts.where(site: params[:site]) if params[:site].present?

    # Default to deleted: true
    @posts = if params[:deleted].present? && !params[:deleted] == 'nil'
               if params[:deleted].casecmp('true') == 0 || params[:deleted] == '1'
                 @posts.where.not(deleted_at: nil)
               else
                 @posts.where(deleted_at: nil)
               end
             else
               @posts.where.not(deleted_at: nil)
             end

    # Default to autoflagged: true
    @posts = if params[:autoflagged].present? && !params[:autoflagged] == 'nil'
               @posts.where(autoflagged: params[:autoflagged])
             else
               @posts = @posts.where(autoflagged: true)
             end

    if params[:from_date].present?
      @posts = @posts.where('`posts`.`created_at` > ?', DateTime.strptime(params[:from_date], '%s'))
    end
    if params[:to_date].present?
      @posts = @posts.where('`posts`.`created_at` < ?', DateTime.strptime(params[:to_date], '%s'))
    end
    if params[:feedback_type].present?
      @posts = @posts.includes(:feedbacks).where(feedbacks: { feedback_type: params[:feedback_type] })
    end
    respond_to do |format|
      format.html
      format.rss { render layout: false }
      format.xml { render 'deleted.rss', layout: false }
    end
  end
end
