# frozen_string_literal: true

class ReviewController < ApplicationController
  before_action :authenticate_user!
  before_action :verify_reviewer
  skip_before_action :verify_authenticity_token, only: [:add_feedback]

  def index
    @posts = if params[:reason].present? && (reason = Reason.find(params[:reason]))
               reason.posts.includes_for_post_row
             else
               Post.all.includes_for_post_row
             end

    @posts = @posts.includes(:reasons)
                   .includes(:feedbacks)
                   .where(feedbacks: { post_id: nil })
                   .order('`posts`.`created_at` DESC')
                   .paginate(page: params[:page], per_page: 100)
    @sites = Site.where(id: @posts.map(&:site_id)).to_a
  end

  def add_feedback
    unless current_user.has_role?(:reviewer)
      render plain: 'Your account is not approved for reviewing', status: :conflict
      return
    end

    not_found unless %w[tp fp naa].include? params[:feedback_type]

    post = Post.find(params[:post_id])
    if post.nil?
      render plain: "Post doesn't exist or already has feedback", status: :conflict
      return
    end

    f = Feedback.new
    f.user = current_user
    f.post = post
    f.feedback_type = params[:feedback_type]
    f.save!

    post.reasons.each do |reason|
      expire_fragment(reason)
    end

    render plain: 'success', status: 200
  end
end
