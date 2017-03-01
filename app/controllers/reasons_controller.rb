class ReasonsController < ApplicationController
  def show
    @reason = Reason.find(params[:id])
    @posts = @reason.posts.select(:id, :created_at, :link, :title, :site_id, :username, :stack_exchange_user_id, 'IF(LENGTH(body)>1,1,0) as body_exists').includes(:reasons, :feedbacks).includes(:feedbacks => [:user, :api_key]).page(params[:page]).order('created_at DESC')

    case params[:filter]
    when "tp"
      @posts = @posts.where(:is_tp => true)
    when "fp"
      @posts = @posts.where(:is_fp => true)
    when "naa"
      @posts = @posts.where(:is_naa => true)
    end

    @sites = Site.where(:id => @posts.map(&:site_id)).to_a

    @counts_by_accuracy_group = @reason.posts.group(:is_tp, :is_fp, :is_naa).count
    @counts_by_feedback = [:is_tp, :is_fp, :is_naa].each_with_index.map do |symbol, i|
      [symbol, @counts_by_accuracy_group.select { |k, v| k[i] }.values.sum]
    end.to_h
  end
  def sites_chart
    h = HTMLEntities.new
    render json: Reason.find(params[:id]).posts.group(:site).count.map{ |k,v| {(k.nil? ? "Unknown" : h.decode(k.site_name))=>v} }.reduce(:merge).select{|k,v| k != "Unknown"}.sort_by {|k,v| v}.reverse
  end
  def accuracy_chart
    @reason = Reason.find(params[:id])
    render json: [{name: "True positives", data: @reason.posts.where(:is_tp => true).group_by_day(:created_at, range: 1.month.ago.to_date..Time.now).count}, {name: "False positives", data: @reason.posts.where(:is_fp => true).group_by_day(:created_at, range: 1.month.ago.to_date..Time.now).count}]
  end
end
