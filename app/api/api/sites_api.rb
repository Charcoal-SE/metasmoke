# frozen_string_literal: true

module API
  class SitesAPI < API::Base
    get '/' do
      std_result Site.all, filter: FILTERS[:sites]
    end
  end
end
