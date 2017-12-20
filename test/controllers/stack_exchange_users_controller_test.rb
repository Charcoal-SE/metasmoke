# frozen_string_literal: true

require 'test_helper'

class StackExchangeUsersControllerTest < ActionController::TestCase
  def setup
    @user = StackExchangeUser.last
  end

  test 'should mark user dead' do
    @user.update(still_alive: true)

    post :dead, params: { id: @user.id }
    assert_response 302 # 302 response because at least one diamond is required, which the test user doesn't have
  end
end
