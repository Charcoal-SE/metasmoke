# frozen_string_literal: true

module API
  class PostsAPI < API::Base
    get '/' do
      std_result Post.all.order(id: :desc), filter: 'HKIFJIHNKLGNFNMFLOGIFLNLJLJ'
    end

    params do
      requires :key, type: String
      requires :from, type: DateTime
      requires :to, type: DateTime
    end
    get 'date_range' do
      std_result Post.where('created_at > ?', params[:from]).where('created_at < ?', params[:to]).order(id: :desc),
                 filter: 'HKIFJIHNKLGNFNMFLOGIFLNLJLJ'
    end

    params do
      requires :key, type: String
      requires :site, type: String
    end
    get 'on_site' do
      std_result Post.joins(:site).where(site: { site_domain: params[:site] }).order(id: :desc), filter: 'HKIFJIHNKLGNFNMFLOGIFLNLJLJ'
    end

    params do
      requires :key, type: String
      requires :urls, type: String
    end
    get 'urls' do
      std_result Post.where(post_link: params[:urls].split(';')).order(id: :desc), filter: 'HKIFJIHNKLGNFNMFLOGIFLNLJLJ'
    end

    params do
      requires :key, type: String
      requires :type, type: String
    end
    get 'with_feedback' do
      std_result Post.joins(:feedbacks).where(feedbacks: { feedback_type: params[:type] }).order(id: :desc),
                 filter: 'HKIFJIHNKLGNFNMFLOGIFLNLJLJ'
    end

    get 'active' do
      std_result Post.where(deleted_at: nil).order(id: :desc), filter: 'HKIFJIHNKLGNFNMFLOGIFLNLJLJ'
    end

    get 'ids/:ids' do
      std_result Post.where(id: params[:ids].split(';')).order(id: :desc), filter: 'HKIFJIHNKLGNFNMFLOGIFLNLJLJ'
    end
  end
end