class ReviewController < ApplicationController
  before_action :authenticate_user!

  def index
    @posts = Post.includes(:feedbacks).where( :feedbacks => { :post_id => nil }).where("body IS NOT NULL").order('created_at DESC').paginate(:page => params[:page], :per_page => 100)
    @sites = Site.where(:id => @posts.map(&:site_id))
  end

  def add_feedback
    not_found unless ["tp", "fp", "naa"].include? params[:feedback_type]

    post = Post.find(params[:post_id])
    not_found if post.nil? or post.feedbacks.present?

    f = Feedback.new
    f.user = current_user
    f.post = post
    f.feedback_type = params[:feedback_type]
    f.save!

    render :nothing => true, :status => 200
  end
end
