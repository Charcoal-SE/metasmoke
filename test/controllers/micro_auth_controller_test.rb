require 'test_helper'

class MicroAuthControllerTest < ActionDispatch::IntegrationTest
  test "should get token request" do
    sign_in users(:approved_user)
    get :token_request, :key => api_keys(:one).key
    assert_response(200)
  end

  test "should authorize app" do
    sign_in users(:approved_user)
    post :authorize, :key => api_keys(:one).key
    assert_nil flash[:danger]
    assert_response(302)
  end

  test "should get authorized" do
    sign_in users(:approved_user)
    get :authorized, :token_id => api_tokens(:one).id, :code => api_tokens(:one).code
    assert_response(200)
  end

  test "should get reject" do
    sign_in users(:approved_user)
    get :reject, :key => api_keys(:one).key
    assert_response(200)
  end

  test "should get invalid key" do
    sign_in users(:approved_user)
    get :invalid_key
    assert_response(200)
  end

  test "should get token" do
    sign_out :user
    get :token, :code => api_tokens(:one).code, :key => api_keys(:one).key
    assert_equal api_tokens(:one).token, JSON.parse(@response.body)['token']
  end
end
