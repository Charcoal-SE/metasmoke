# frozen_string_literal: true

require 'test_helper'

class ReviewControllerTest < ActionController::TestCase
  test 'should require login' do
    get :index
    assert_redirected_to new_user_session_url
  end

  test 'should require account approval' do
    sign_in users(:unapproved_user)
    assert_raises ActionController::RoutingError do
      get :index
    end
  end

  test 'should load while logged in' do
    sign_in users(:approved_user)
    get :index
    assert_response :success
  end

  test 'should submit feedback' do
    sign_in users(:approved_user)
    post :add_feedback, params: { feedback_type: 'tp', post_id: posts(:post_23653).id }
    assert_response :success
  end
end
