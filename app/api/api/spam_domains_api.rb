# frozen_string_literal: true

module API
  class SpamDomainsAPI < API::BaseWithAuth
    get '/' do
      std_result SpamDomain.all.order(id: :desc), filter: FILTERS[:domains]
    end

    get 'name/:name' do
      std_result SpamDomain.where(domain: params[:name]).order(id: :desc), filter: FILTERS[:domains]
    end

    get ':id/posts' do
      std_result SpamDomain.find(params[:id]).posts.order(id: :desc), filter: FILTERS[:posts]
    end

    before do
      authenticate_user!
      role :core
    end
    params do
      requires :key, type: String
      requires :token, type: String
      requires :tag, type: String
    end
    post ':id/tags/add' do
      tag = DomainTag.find_or_create_by name: params[:tag]
      domain = SpamDomain.find params[:id]
      domain.domain_tags << tag
      std_result domain.domain_tags.order(id: :desc), filter: FILTERS[:tags]
    end
  end
end
