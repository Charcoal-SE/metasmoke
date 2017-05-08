require 'test_helper'

class ApiKeysControllerTest < ActionController::TestCase
  test "should get index" do
    sign_in users(:admin_user)
    get :index
    assert_response(200)
  end

  test "should get new" do
    sign_in users(:admin_user)
    get :new
    assert_response(200)
  end

  test "should create new key" do
    sign_in users(:admin_user)
    post :create, params: { api_key: { key: "71ab6e12d4287e6d1cd6549f039e46646ae379a709bd359e9231a385e5ff970f", app_name: "new_tests" } }
    assert_response(302)
  end

  test "should revoke write tokens" do
    sign_in users(:admin_user)
    before_test_count = ApiToken.count

    delete :revoke_write_tokens, params: { id: api_keys(:one).id }
    assert_response(302)

    # Assert that the count before the test is more than the count
    # after the test; i.e. some tokens disappeared
    assert_operator before_test_count, :>, ApiToken.count
  end
end
