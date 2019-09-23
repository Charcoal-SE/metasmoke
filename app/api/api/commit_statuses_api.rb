# frozen_string_literal: true

module API
  class CommitStatusesAPI < API::BaseWithoutAuth
    include API::Authentication
    
    get '/' do
      std_result CommitStatus.all.order(id: :desc), filter: FILTERS[:commits]
    end
  end
end
