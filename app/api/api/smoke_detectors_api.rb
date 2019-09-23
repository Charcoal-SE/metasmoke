# frozen_string_literal: true

module API
  class SmokeDetectorsAPI < API::BaseWithoutAuth
    include API::Authentication
    
    get '/' do
      std_result SmokeDetector.all.order(id: :desc), filter: FILTERS[:smokeys]
    end
  end
end
