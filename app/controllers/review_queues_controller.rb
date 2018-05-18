# frozen_string_literal: true

class ReviewQueuesController < ApplicationController
  before_action :set_queue, except: [:index]
  before_action :verify_permissions, except: [:index]

  def index
    @queues = ReviewQueue.all.includes(:items)
  end

  def queue; end

  def next_item
    unreviewed = ReviewItem.unreviewed_by(@queue, current_user)
    if unreviewed.empty?
      render plain: "You've reviewed all available items!"
    else
      item = unreviewed.first
      render "#{item.reviewable_type.underscore.pluralize}/_review_item.html.erb", locals: { queue: @queue, item: item }, layout: nil
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
    @all = params[:all] == '1'

    @reviews =
      if @all
        ReviewResult
      else
        ReviewResult.where(user: current_user)
      end
      .all.joins(:item).where(review_items: { review_queue_id: @queue.id })
      .order(created_at: :desc).paginate(page: params[:page], per_page: 100)
  end

  private

  def set_queue
    @queue = ReviewQueue[params[:name]]
  end

  def verify_permissions
    return if user_signed_in? && current_user.has_role?(@queue.privileges)
    not_found
  end
end
