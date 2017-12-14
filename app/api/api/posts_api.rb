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
    get 'between' do
      std_result Post.where('created_at > ?', params[:from]).where('created_at < ?', params[:to]).order(id: :desc),
                 filter: 'HKIFJIHNKLGNFNMFLOGIFLNLJLJ'
    end

    params do
      requires :key, type: String
      requires :site, type: String
    end
    get 'site' do
      std_result Post.joins(:site).where(sites: { site_domain: params[:site] }).order(id: :desc), filter: 'HKIFJIHNKLGNFNMFLOGIFLNLJLJ'
    end

    params do
      requires :key, type: String
      requires :urls, type: String
    end
    get 'urls' do
      std_result Post.where(link: params[:urls].split(',')).order(id: :desc), filter: 'HKIFJIHNKLGNFNMFLOGIFLNLJLJ'
    end

    params do
      requires :key, type: String
      requires :type, type: String
    end
    get 'feedback' do
      std_result Post.joins(:feedbacks).where(feedbacks: { feedback_type: params[:type] }).order(id: :desc),
                 filter: 'HKIFJIHNKLGNFNMFLOGIFLNLJLJ'
    end

    get 'undeleted' do
      std_result Post.where(deleted_at: nil).order(id: :desc), filter: 'HKIFJIHNKLGNFNMFLOGIFLNLJLJ'
    end

    get ':ids' do
      std_result Post.where(id: params[:ids].split(',')).order(id: :desc), filter: 'HKIFJIHNKLGNFNMFLOGIFLNLJLJ'
    end

    get ':id/reasons' do
      std_result Post.find(params[:id]).reasons.order(id: :desc), filter: 'GGFLNFJLJJJHHKMIFOLOL'
    end
  end
end
