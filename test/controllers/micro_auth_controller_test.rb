# frozen_string_literal: true

require 'test_helper'

class MicroAuthControllerTest < ActionController::TestCase
  test 'should get token request' do
    sign_in users(:approved_user)
    get :token_request, params: { key: api_keys(:one).key }
    assert_response(200)
  end

  test 'should authorize app' do
    sign_in users(:approved_user)
    post :authorize, params: { key: api_keys(:one).key }
    assert_nil flash[:danger]
    assert_response(302)
  end

  test 'should get authorized' do
    sign_in users(:approved_user)
    get :authorized, params: { token_id: api_tokens(:one).id, code: api_tokens(:one).code }
    assert_response(200)
  end

  test 'should get reject' do
    sign_in users(:approved_user)
    get :reject, params: { key: api_keys(:one).key }
    assert_response(200)
  end

  test 'should get invalid key' do
    sign_in users(:approved_user)
    get :invalid_key
    assert_response(200)
  end

  test 'should get token' do
    sign_out :user
    get :token, params: { code: api_tokens(:one).code, key: api_keys(:one).key }
    assert_equal api_tokens(:one).token, JSON.parse(@response.body)['token']
  end

  test 'should run whole auth cycle' do
    sign_in users(:approved_user)
    get :token_request, params: { key: api_keys(:one).key }
    post :authorize, params: { key: api_keys(:one).key }

    token = assigns(:token)

    sign_out :user
    get :token, params: { code: token.code, key: api_keys(:one).key }

    assert_equal token.token, JSON.parse(@response.body)['token']
  end
end
