# frozen_string_literal: true

module API
  class SitesAPI < API::BaseWithoutAuth
    # Deliberately not authenticated
    
    get '/' do
      std_result Site.all, filter: FILTERS[:sites]
    end
  end
end
