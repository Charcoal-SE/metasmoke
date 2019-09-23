# frozen_string_literal: true

module API
  class BaseWithAuth < BaseWithoutAuth
    before do
      authenticate_app!
    end
  end
end