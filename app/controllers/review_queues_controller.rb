# frozen_string_literal: true

class ReviewQueuesController < ApplicationController
  before_action :set_queue, except: [:index]
  before_action :verify_permissions, except: [:index]
  before_action :verify_developer, only: [:recheck_items]
  before_action :verify_admin, only: [:delete]

  def index
    @queues = ReviewQueue.all.includes(:items)
  end

  def queue; end

  def next_item
    response.cache_control = 'max-age=0, private, must-revalidate, no-store'
    unreviewed = if params[:site_id].present?
                   @queue.next_items(current_user) do |c|
                     reviewable_table = @queue.reviewable_type.pluralize.underscore
                     c.joins("INNER JOIN `#{reviewable_table}` AS reviewable ON reviewable.id = review_items.reviewable_id")
                      .where(reviewable: filter_params([:site_id]))
                   end
                 else
                   @queue.next_items(current_user)
                 end

    while !unreviewed.empty? && unreviewed.first.reviewable.nil?
      unreviewed.first.update(completed: true)
      unreviewed = ReviewItem.unreviewed_by(@queue, current_user)
    end

    if unreviewed.empty?
      render plain: "You've reviewed all available items!"
    else
      item = unreviewed.first
      render "#{item.reviewable_type.underscore.pluralize}/_review_item.html.erb",
             locals: { queue: @queue, item: item }, layout: nil
    end
  end

  def submit
    unless (@queue.responses.map { |r| r[1] } + ['skip']).include? params[:response]
      render json: { status: 'invalid' }, status: 400
      return
    end

    @item = ReviewItem.find params[:item_id]

    # Prevent the same item from being reviewed after it is completed, or twice by the same user.
    if (@item.completed && ReviewResult.where(item: @item).where.not(result: 'skip').exists?) ||
       ReviewResult.where(user: current_user, item: @item).where.not(result: 'skip').exists?

      render json: { status: 'duplicate' }, status: 409
      return
    end

    ReviewResult.create user: current_user, result: params[:response], item: @item

    unless params[:response] == 'skip'
      @item.reviewable.custom_review_action(@queue, @item, current_user, params[:response]) if @item.reviewable.respond_to? :custom_review_action
      if @item.reviewable.respond_to?(:should_dq?) && @item.reviewable.should_dq?(@queue)
        @item.update(completed: true)
      end
    end

    render json: { status: 'ok' }
  end

  def item
    @item = ReviewItem.find(params[:item_id])
    render :queue
  end

  def reviews
    @all = params[:all].present? && params[:all] == '1'
    @reviews = ReviewResult.joins(:item).includes(:item).where(review_items: { review_queue_id: @queue })
    @reviews = @reviews.where(Arel.sql('review_items.reviewable_id IS NOT NULL AND review_items.reviewable_type IS NOT NULL'))
    @reviews = @reviews.where(user: current_user) if @all == false
    @reviews = @reviews.where(user_id: params[:user]) if params[:user].present?
    @reviews = @reviews.where(result: params[:response]) if params[:response].present?
    @reviews = @reviews.joins(:user, user: :roles).where(roles: { name: params[:role] }) if params[:role].present?
    @reviews = @reviews.order(created_at: :desc).paginate(page: params[:page], per_page: 100)
  end

  def recheck_items
    ReviewQueueRecheckItemsJob.perform_later(@queue.id)
    flash[:info] = 'Checking started in background.'
    redirect_back fallback_location: review_queues_path
  end

  def delete
    @review = ReviewResult.find(params[:id])
    @review.destroy
    head :no_content
  end

  private

  def set_queue
    @queue = ReviewQueue[params[:name]]
  end

  def verify_permissions
    return if user_signed_in? && current_user.has_role?(@queue.privileges)
    not_found
  end

  def filter_params(allowed)
    allowed.map { |p| params[p].present? ? [p, params[p]] : nil }.compact.to_h
  end
end
