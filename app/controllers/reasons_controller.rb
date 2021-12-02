# frozen_string_literal: true

class ReasonsController < ApplicationController
  before_action :verify_core, only: [:update_description]

  def show
    @reason = Reason.find(params[:id])

    # Note: Body nil check as body_exists
    @posts = Redis::Reason.find(params[:id]).intersect('posts', type: :zset)
    # @posts = @reason.posts
    #                 .select(:id, :created_at, :link, :title, :site_id, :username, :stack_exchange_user_id, 'IF(LENGTH(body)>1,1,0) as body_exists')
    #                 .includes(:reasons, :feedbacks)
    #                 .includes(feedbacks: [:user, :api_key])
    #                 .paginate(page: params[:page], per_page: 100)
    #                 .order(Arel.sql('created_at DESC'))

    @total = @posts.cardinality
    @counts_by_feedback = {
      is_tp: @posts.intersect('tps').cardinality,
      is_fp: @posts.intersect('fps').cardinality,
      is_naa: @posts.intersect('naas').cardinality
    }

    case params[:filter]
    when 'tp'
      @posts = @posts.intersect('tps')
    when 'fp'
      @posts = @posts.intersect('fps')
    when 'naa'
      @posts = @posts.intersect('naas')
    end

    @posts = @posts.paginate(params[:page], 100) { |id| Redis::Post.new(id) }

    @sites = Site.where(id: @posts.map(&:site_id)).to_a
  end

  def sites_chart
    h = HTMLEntities.new
    render json: Reason.find(params[:id])
                       .posts
                       .group(:site)
                       .count
                       .map { |k, v| { (k.nil? ? 'Unknown' : h.decode(k.site_name)) => v } }
                       .reduce(:merge)
                       .reject { |k, _v| k == 'Unknown' }
                       .sort_by { |_k, v| v }.reverse
  end

  def accuracy_chart
    @reason = Reason.find(params[:id])
    render json: [
      {
        name: 'True positives',
        data: @reason.posts.where(is_tp: true).group_by_day(:created_at, range: 1.month.ago.to_date..Time.now).count
      },
      {
        name: 'False positives',
        data: @reason.posts.where(is_fp: true).group_by_day(:created_at, range: 1.month.ago.to_date..Time.now).count
      }
    ]
  end

  def update_description
    @reason = Reason.find(params[:id])
    @reason.update(description: params[:description])
    redirect_back fallback_location: reason_path(@reason)
  end
end
