class SearchController < ApplicationController
  def search_results
    username = params[:username].presence || '*'
    title = params[:title].presence || '*'
    body = params[:body].presence || '*'
    @results = Post.where("username LIKE :username AND title LIKE :title AND body LIKE :body", username: "%" + username + "%", title: "%" + title + "%", body: "%" + body + "%").paginate(:page => params[:page], :per_page => 100).order("created_at DESC")

    if params[:site].present?
      site_id = Site.find_by_site_name(params[:site])
      @results = @results.where(:site_id => site_id)
    end

    @sites = Site.where(:id => @results.map(&:site_id))

    render :search
  end
end
