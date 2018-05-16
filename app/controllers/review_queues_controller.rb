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
    render json: { status: 'invalid' }, status: 400 unless @queue.responses.map { |r| r[1] }.include? params[:response]
    @item = ReviewItem.find params[:item_id]

    ReviewResult.create user: current_user, result: params[:response], item: @item

    @item.reviewable.custom_review_action(@queue, @item, current_user, params[:response]) if @item.reviewable.respond_to? :custom_review_action
    if @item.reviewable.respond_to?(:should_dq?) && @item.reviewable.should_dq?(@queue)
      @item.update(completed: true)
    end

    render json: { status: 'ok' }
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
