# frozen_string_literal: true

module API
  class DomainTagsAPI < API::Base
    prefix :domain_tags

    get '/' do
      std_result DomainTag.all.order(id: :desc), filter: 'NOL'
    end

    get 'name/:name' do
      std_result DomainTag.where(name: params[:name]).order(id: :desc), filter: 'NOL'
    end

    get ':id/domains' do
      std_result DomainTag.find(params[:id]).spam_domains, filter: 'HN'
    end
  end
end
