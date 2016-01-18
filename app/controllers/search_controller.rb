class SearchController < ApplicationController
  def search_results
    username = params[:username] || ""
    title = params[:title] || ""
    body = params[:body] || ""
    why = params[:why] || ""

    @results = Post.where("IFNULL(username, '') LIKE :username AND IFNULL(title, '') LIKE :title AND IFNULL(body, '') LIKE :body AND IFNULL(why, '') like :why", username: "%" + username + "%", title: "%" + title + "%", body: "%" + body + "%", why: "%" + why + "%").paginate(:page => params[:page], :per_page => 100).order("created_at DESC").includes(:reasons).includes(:feedbacks)

    if params[:site].present?
      site_id = Site.find_by_site_name(params[:site])
      @results = @results.where(:site_id => site_id)
    end

    @sites = Site.where(:id => @results.map(&:site_id))

    render :search
  end
end
