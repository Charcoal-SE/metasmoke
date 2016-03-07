class GraphsController < ApplicationController
  def index
    if params[:timeframe] == "all"
      @posts = Post.all
    else
      @posts = Post.where("created_at >= ?", 1.month.ago)
    end
  end
end
