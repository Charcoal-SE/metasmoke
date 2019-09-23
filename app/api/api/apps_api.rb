# frozen_string_literal: true

module API
  class AppsAPI < API::BaseWithoutAuth
    include API::Authentication
    
    get '/' do
      std_result APIKey.all.order(id: :desc), filter: FILTERS[:apps]
    end
  end
end
