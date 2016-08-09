require 'test_helper'

class AuthenticationControllerTest < ActionDispatch::IntegrationTest
  test "should get status" do
    get authentication_status_url
    assert_response :success
  end

  test "should get redirect_target" do
    get authentication_redirect_target_url
    assert_response :success
  end

end
