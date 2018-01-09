# frozen_string_literal: true

require 'test_helper'

class APIControllerTest < ActionController::TestCase
  test 'should get index' do
    sign_out(:users)
    get :api_docs

    assert_response 302
  end

  # Hopefully at some point I will write tests for V2. (Ha!)
end
