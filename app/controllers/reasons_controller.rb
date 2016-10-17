class ReasonsController < ApplicationController
  def show
    @reason = Reason.find(params[:id])
    @posts = @reason.posts.select(:id, :created_at, :link, :title, :site_id, 'IF(LENGTH(body)>1,1,0) as body_exists').includes(:reasons, :feedbacks).includes(:feedbacks => [:user, :api_key]).paginate(:page => params[:page], :per_page => 100).order('created_at DESC')
    @sites = Site.where(:id => @posts.map(&:site_id)).to_a
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
