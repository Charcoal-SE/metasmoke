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
    delete :revoke_app, params: { key_id: api_keys(:one).id }
    assert_response(302)
    assert_nil flash[:danger]
    assert_operator before_test_count, :>, ApiToken.count
  end

  test "should get two-factor status page" do
    sign_in users(:approved_user)
    get :tf_status
    assert_response 200
  end

  test "should add a secret to the account" do
    sign_in users(:approved_user)
    post :enable_2fa
    users(:approved_user).reload
    assert_response 200
    assert_not_nil assigns(:qr_uri)
    assert_not_nil users(:approved_user).two_factor_token
  end

  test "should get enable code confirmation page" do
    sign_in users(:approved_user)
    get :enable_code
    assert_response 200
  end

  test "should confirm enable code" do
    sign_in users(:two_factor_confirming)
    totp = ROTP::TOTP.new(users(:two_factor_confirming).two_factor_token)
    post :confirm_enable_code, params: { code: totp.now }
    users(:two_factor_confirming).reload
    assert_nil flash[:danger]
    assert_not_nil flash[:success]
    assert_equal true, users(:two_factor_confirming).enabled_2fa
    assert_response 302
  end

  test "should get disable code confirmation page" do
    sign_in users(:two_factor_full)
    get :disable_code
    assert_response 200
  end

  test "should confirm disable code" do
    sign_in users(:two_factor_full)
    totp = ROTP::TOTP.new(users(:two_factor_full).two_factor_token)
    post :confirm_disable_code, params: { code: totp.now }
    users(:two_factor_full).reload
    assert_nil flash[:danger]
    assert_not_nil flash[:success]
    assert_equal false, users(:two_factor_full).enabled_2fa
    assert_nil users(:two_factor_full).two_factor_token
    assert_response 302
  end
end
