# frozen_string_literal: true

module API
  class DomainTagsAPI < API::BaseWithoutAuth
    include API::Authentication
    
    get '/' do
      std_result DomainTag.all.order(id: :desc), filter: FILTERS[:tags]
    end

    get 'name/:name' do
      std_result DomainTag.where(name: params[:name]).order(id: :desc), filter: FILTERS[:tags]
    end

    get ':id/domains' do
      std_result DomainTag.find(params[:id]).spam_domains, filter: FILTERS[:domains]
    end
  end
end
