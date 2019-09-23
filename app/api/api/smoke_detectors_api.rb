# frozen_string_literal: true

module API
  class SmokeDetectorsAPI < API::BaseWithAuth
    get '/' do
      std_result SmokeDetector.all.order(id: :desc), filter: FILTERS[:smokeys]
    end
  end
end
