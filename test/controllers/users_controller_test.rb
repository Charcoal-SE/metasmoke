require 'test_helper'

class UsersControllerTest < ActionController::TestCase
  test "should get apps list" do
    sign_in users(:approved_user)
    get :apps
    assert_response(200)
  end

  test "should revoke app access" do
    sign_in users(:approved_user)
    before_test_count = ApiToken.count
    delete :revoke_app, :params => { :key_id => api_keys(:one).id }
    assert_response(302)
    assert_nil flash[:danger]
    assert_operator before_test_count, :>, ApiToken.count
  end
end
