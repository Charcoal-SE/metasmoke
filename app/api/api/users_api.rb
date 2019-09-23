# frozen_string_literal: true

module API
  class UsersAPI < API::BaseWithoutAuth
    # Deliberately not authenticated
    
    get '/' do
      std_result User.all.order(id: :desc), filter: FILTERS[:users]
    end
    get '/with_role/:role' do
      std_result User.with_role(params[:role]).order(id: :desc), filter: FILTERS[:users]
    end
  end
end
