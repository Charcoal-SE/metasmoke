# frozen_string_literal: true

module API
  class AppsAPI < API::Base
    get '/' do
      std_result APIKey.all.order(id: :desc), filter: 'MOGLMLJKJKJMNIMGHGKHJKGMOONLMOFGLNIIJLHIFJMLN'
    end
  end
end
