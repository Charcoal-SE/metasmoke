class RSSController < ApplicationController
  def autoflagged
    @posts = Post.order('created_at DESC').paginate(page: params[:page], per_page: 50)
    respond_to do |format|
      format.html
      format.rss { render :layout => false }
    end
  end
end
