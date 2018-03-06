class RSSController < ApplicationController
  def autoflagged
    @posts = Post.order('created_at DESC').paginate(page: params[:page], per_page: 50)
    if params[:site].present?
      @posts = @posts.where(site: params[:site])
    end
    if params[:deleted].present?
      if params[:deleted].downcase == 'true' || params[:deleted] == '1'
        @posts = @posts.where.not(deleted_at: nil)
      else
        @posts = @posts.where(deleted_at: nil)
      end
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
      format.rss { render :layout => false }
    end
  end
end
