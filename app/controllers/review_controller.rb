# frozen_string_literal: true

class ReviewController < ApplicationController
  before_action :authenticate_user!
  before_action :verify_reviewer, except: [:delete_skip]
  before_action :verify_admin, only: [:delete_skip]
  skip_before_action :verify_authenticity_token, only: [:add_feedback]

  def index
    @posts = if params[:reason].present?
               Post.joins(:posts_reasons).where(posts_reasons: { reason_id: params[:reason] }).includes_for_post_row
             else
               Post.all.includes_for_post_row
             end

    reviewed = ReviewResult.where(user: current_user).map(&:post_id)
    @posts = @posts.left_joins(:feedbacks)
                   .where(feedbacks: { post_id: nil })
                   .where.not(id: reviewed)
                   .order(Arel.sql('`posts`.`created_at` DESC'))
                   .paginate(page: params[:page], per_page: 100)
    @sites = Site.where(id: @posts.map(&:site_id)).to_a
  end

  def add_feedback
    not_found unless %w[tpu fp naa].include? params[:feedback_type]

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

    ReviewResult.create(post: post, user: current_user, feedback: f, result: params[:feedback_type])

    post.reasons.each do |reason|
      expire_fragment(reason)
    end

    render plain: 'success', status: 200
  end

  def skip
    post = Post.find params[:post_id]
    ReviewResult.create post: post, user: current_user, result: 'skip'
    render plain: 'success', status: 200
  end

  def history
    @results = ReviewResult.all.order(id: :desc).paginate(page: params[:page], per_page: 100)
    @posts = Post.where(id: @results.map(&:post_id)).includes_for_post_row
    @sites = Site.where(id: @posts.map(&:site_id))
  end

  def delete_skip
    ReviewResult.find(params[:result]).destroy!
    flash[:success] = 'Removed review.'
    redirect_to review_history_path
  end
end
