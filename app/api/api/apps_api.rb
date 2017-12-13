# frozen_string_literal: true

module API
  class AppsAPI < API::Base
    prefix :apps

    get '/' do
      std_result APIKey.all.order(id: :desc), filter: 'MMIGHGKIMLJJIMHGNNONNMNMGFNFNJOMMIMLJHNFIH'
    end
  end
end
