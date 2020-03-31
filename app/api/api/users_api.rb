# frozen_string_literal: true

module API
  class UsersAPI < API::Base
    get '/' do
      std_result User.all.order(id: :desc), filter: FILTERS[:users]
    end

    get '/with_role/:role' do
      std_result User.with_role(params[:role]).order(id: :desc), filter: FILTERS[:users]
    end

    before do
      authenticate_user!
    end
    params do
      requires :key, type: String
      requires :token, type: String
    end
    get '/current' do
      std_result User.where(id: current_user.id).map { |u| u.attributes.merge(roles: u.roles) }, filter: FILTERS[:users]
    end
  end
end
