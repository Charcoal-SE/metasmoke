require 'test_helper'

class ReviewControllerTest < ActionController::TestCase
  test 'should require login' do
    get :index
    assert_redirected_to new_user_session_url
  end

  test 'should require account approval' do
    sign_in users(:unapproved_user)
    get :index
    assert_redirected_to new_user_session_url
  end

  test 'should load while logged in' do
    sign_in users(:approved_user)
    get :index
    assert_response :success
  end
end
