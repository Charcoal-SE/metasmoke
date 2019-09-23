# frozen_string_literal: true

module API
  class Authentication < BaseWithoutAuth
    before do
      authenticate_app!
    end
  end
end
