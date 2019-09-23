# frozen_string_literal: true

module API
  class AppsAPI < API::BaseWithAuth
    get '/' do
      std_result APIKey.all.order(id: :desc), filter: FILTERS[:apps]
    end
  end
end
