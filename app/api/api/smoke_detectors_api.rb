# frozen_string_literal: true

module API
  class SmokeDetectorsAPI < API::Base
    get '/' do
      std_result SmokeDetector.all.order(id: :desc), filter: 'GFKKKIGGLHLOMMHN'
    end
  end
end
