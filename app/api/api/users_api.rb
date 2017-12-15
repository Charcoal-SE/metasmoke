# frozen_string_literal: true

module API
  class UsersAPI < API::Base
    get '/' do
      std_result User.all.order(id: :desc), filter: FILTERS[:users]
    end
  end
end
